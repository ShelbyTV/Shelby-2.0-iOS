//
//  SPVideoExtractor.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoExtractor.h"

#import "AppDelegate.h"
#import "Video.h"

@interface SPVideoExtractor () <UIWebViewDelegate>

//non web-view extractions
@property (nonatomic, strong) STVYouTubeExtractor *stvYTExtractor;
@property (nonatomic, strong) LBYouTubeExtractor *ytExtractor;
@property (nonatomic, strong) YTVimeoExtractor *vimeoExtractor;
//web-view extractions
@property (nonatomic) UIWebView *webView;


@property (nonatomic) NSTimer *startNextExtractionTimer;
@property (nonatomic) NSTimer *currentExtractionTimeoutTimer;
// array of {kSPVideoExtractorVideoKey: Video*, kSPVideoExtractorBlockKey: extraction_complete_block} waiting to be processed
@property (nonatomic) NSMutableArray *highPriorityExtractionQueue;
// same dictionary as above, but without extraction_complete_block
@property (nonatomic) NSMutableArray *warmCacheExtractionQueue;
// {kSPVideoExtractorVideoKey: Video*, kSPVideoExtractorBlockKey: extraction_complete_block} currently processing
@property (nonatomic, strong) NSDictionary *currentlyExtracting;
// array of {kSPVideoExtractorVideoObjectIDKey: Video*, kSPVideoExtractorExtractedURLStringKey: NSString*, kSPVideoExtractorExtractedAtKey: NSDate*}
// Videosalready processed, 
@property (nonatomic) NSMutableDictionary *extractedURLCache;

// this gate is used to make sure video extraction notification is from the current web view (not the previous one)
@property (atomic, assign) BOOL currentWebViewDidStartLoading;

@end

//for extraction
NSString * const kSPVideoExtractorVideoKey = @"video";
NSString * const kSPVideoExtractorBlockKey = @"block";
//extraction caching
NSString * const kSPVideoExtractorVideoObjectIDKey = @"videoObjectID";
NSString * const kSPVideoExtractorExtractedURLStringKey = @"extractedURLString";
NSString * const kSPVideoExtractorExtractedAtKey = @"extractedAt";
#define EXTRACTED_URL_TTL_S -300 //URLs are valid for 300s (5m)

@implementation SPVideoExtractor

#pragma mark - Singleton Methods
+ (SPVideoExtractor *)sharedInstance
{    
    static SPVideoExtractor *sharedInstance = nil;
    static dispatch_once_t extractorToken = 0;
    dispatch_once(&extractorToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });

    return sharedInstance;
}

- (id)init{
    self = [super init];
    if(self){
        _extractedURLCache = [@{} mutableCopy];
        _warmCacheExtractionQueue = [@[] mutableCopy];
        _highPriorityExtractionQueue = [@[] mutableCopy];
    }
    return self;
}

#pragma mark - Public Methods

- (void)URLForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock highPriority:(BOOL)jumpQueue
{
    STVAssert(completionBlock, @"urlForVideo expects an extraction block");
    STVAssert(video, @"urlForVideo expects a video");

    @synchronized(self){
        NSString *alreadyExtractedURL = [self getCachedURLForVideo:video];
        if(alreadyExtractedURL){
            if(completionBlock){
                completionBlock(alreadyExtractedURL, NO);
            }
        } else {
            NSDictionary *extractionDict = @{kSPVideoExtractorVideoKey: video,
                                             kSPVideoExtractorBlockKey: completionBlock};
            if(jumpQueue){
                //a jumpQueue means video was changed and we didn't have URL pre-extracted
                //we can cancel all extractions b/c new preloading & cache warming will be sent later
                [self cancelAllExtractions];
            }
            [self.highPriorityExtractionQueue addObject:extractionDict];
            [self scheduleNextExtraction];
        }
    }
}

- (void)warmCacheForVideo:(Video *)video
{
    @synchronized(self){
        if([self.warmCacheExtractionQueue count] < 15){
        [self.warmCacheExtractionQueue addObject:@{kSPVideoExtractorVideoKey: video}];
            [self scheduleNextExtraction];
        }
    }
}

- (void)warmCacheForVideoContainer:(id<ShelbyVideoContainer>)videoContainer
{
    STVAssert([videoContainer conformsToProtocol:@protocol(ShelbyVideoContainer)], @"warm cache for entity expected a video container");
    [self warmCacheForVideo:[videoContainer containedVideo]];
}

- (void)scheduleNextExtraction
{
    @synchronized(self){
        if(!self.startNextExtractionTimer){
            self.startNextExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                                             target:self
                                                                           selector:@selector(extractNextVideoFromQueue)
                                                                           userInfo:nil
                                                                            repeats:NO];
        } else {
            /* timer already scheduled */
        }
    }
}

- (void)cancelAllExtractions
{
    @synchronized(self){
        [self cancelCurrentExtraction];
        
        for (NSDictionary *queuedExtraction in self.highPriorityExtractionQueue) {
            extraction_complete_block completionBlock = queuedExtraction[kSPVideoExtractorBlockKey];
            if(completionBlock){
                completionBlock(nil, NO);
            }
        }
        [self.highPriorityExtractionQueue removeAllObjects];
        [self.warmCacheExtractionQueue removeAllObjects];
    }
}

- (void)cancelCurrentExtraction
{
    //notification observer is also synchronized to prevent us from sending messages
    //to players after cancellation
    @synchronized(self){
        [[NSNotificationCenter defaultCenter] removeObserver:self];

        //fail current extraction
        if(self.currentlyExtracting){
            extraction_complete_block currentCompletionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
            [self destroyWebView];
            [self destroyYTExtractor];
            [self destroyVimeoExtractor];
            self.currentlyExtracting = nil;
            if(currentCompletionBlock){
                currentCompletionBlock(nil, NO);
            }
        } else {
            STVAssert(self.webView == nil, @"should not have a web view w/o currently Extracting");
        }
        
        [self.startNextExtractionTimer invalidate];
        self.startNextExtractionTimer = nil;
        [self.currentExtractionTimeoutTimer invalidate];
        self.currentExtractionTimeoutTimer = nil;
    }
}

#pragma mark - Private Methods

- (NSDictionary *)nextItemForExtraction
{
    @synchronized(self){
        NSDictionary *upNext = nil;
        if ([self.highPriorityExtractionQueue count]) {
            upNext = self.highPriorityExtractionQueue[0];
            [self.highPriorityExtractionQueue removeObject:upNext];
        } else if ([self.warmCacheExtractionQueue count]) {
            upNext = self.warmCacheExtractionQueue[0];
            [self.warmCacheExtractionQueue removeObject:upNext];
        }
        return upNext;
    }
}

- (void)extractNextVideoFromQueue
{
    @synchronized(self) {
        
        self.startNextExtractionTimer = nil;
        
        if(self.currentlyExtracting){
            return;
        }
        
        NSDictionary *nextExtraction = [self nextItemForExtraction];
        
        if (nextExtraction) {
            STVAssert(self.webView == nil, @"webview should be nil");
            
            self.currentlyExtracting = nextExtraction;
            Video *video = self.currentlyExtracting[kSPVideoExtractorVideoKey];
            STVAssert(video, @"expected valid job w/ video");
            
            NSString *alreadyExtractedURL = [self getCachedURLForVideo:video];
            if(alreadyExtractedURL){
                //already extracted while it was waiting
                extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
                if(completionBlock){
                    completionBlock(alreadyExtractedURL, NO);
                }
                self.currentlyExtracting = nil;
                [self scheduleNextExtraction];
                return;
                
            } else {
                //perform actual extraction
                if ([video.providerName isEqualToString:@"youtube"]) {
                    //the LBYouTube extractor parses a regular webpage, which seems to work better for more videos
                    //so we just fall back to the STVYouTubeExtractor when LB fails
                    [self lbYouTube:video];
                    
                } else if ([video.providerName isEqualToString:@"vimeo"]) {
                    [self ytVimeo:video];
                
                } else if ([video.providerName isEqualToString:@"dailymotion"]) {
                    //WebView based extraction...
                    STVAssert(!self.webView, @"should not have a web view already");
                    [self createWebView];
                    
                    [self loadDailyMotionVideo:video];
                    
                    STVAssert(self.currentExtractionTimeoutTimer == nil, @"shouldn't have a current extraction timeout timer");
                    self.currentExtractionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                                                          target:self
                                                                                        selector:@selector(extractionTimedOut:)
                                                                                        userInfo:self.currentlyExtracting
                                                                                         repeats:NO];
                } else {
                    STVAssert(NO, @"Invalid video provider");
                }
            }
        } else {
            //nothing to extract or currently extracting, do nothing
        }
    }
}

- (void)createWebView
{
    self.currentWebViewDidStartLoading = NO;
    
    CGRect frame = CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight);
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(frame.size.width/2.0f, frame.size.height/2.0f, 2.0f, 2.0f)];
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.mediaPlaybackRequiresUserAction = NO;
    self.webView.mediaPlaybackAllowsAirPlay = YES;
    self.webView.hidden = YES;
    //important to set delegate, even if we don't implement any of the methods
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    STVAssert(self.webView == webView, @"we should only have one web view at a time");
    self.currentWebViewDidStartLoading = YES;
}

- (void)destroyWebView
{
    [self.webView stopLoading];
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView stopLoading];
    [self.webView setDelegate:nil];
    [self.webView removeFromSuperview];
    [self setWebView:nil];
    
    self.currentWebViewDidStartLoading = NO;
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}

- (void)destroySTVYTExtractor
{
    [self.stvYTExtractor stopExtracting];
    self.stvYTExtractor.delegate = nil;
    self.stvYTExtractor = nil;
}

- (void)destroyYTExtractor
{
    [self.ytExtractor stopExtracting];
    self.ytExtractor.delegate = nil;
    self.ytExtractor = nil;
}

- (void)destroyVimeoExtractor
{
    //has no cancel
    self.vimeoExtractor.delegate = nil;
    self.vimeoExtractor = nil;
}

- (void)stvYouTube:(Video *)video
{
    //TODO - set Quality based on device (iPad vs iPhone)
    self.stvYTExtractor = [[STVYouTubeExtractor alloc] initWithID:video.providerID quality:STVYouTubeVideoQualityMedium];
    self.stvYTExtractor.delegate = self;
    [self.stvYTExtractor startExtracting];
}

- (void)lbYouTube:(Video *)video
{
    //TODO - set Quality based on device (iPad vs iPhone)
    self.ytExtractor = [[LBYouTubeExtractor alloc] initWithID:video.providerID quality:LBYouTubeVideoQualityLarge];
    self.ytExtractor.delegate = self;
    [self.ytExtractor startExtracting];
}

- (void)ytVimeo:(Video *)video
{
    //TODO - set Quality based on device (iPad vs iPhone)
    self.vimeoExtractor = [[YTVimeoExtractor alloc] initWithID:video.providerID quality:YTVimeoVideoQualityHigh];
    self.vimeoExtractor.delegate = self;
    [self.vimeoExtractor start];
}

//deprecated
- (void)loadYouTubeVideo:(Video *)video
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *videoExtractor = @"<html><body><div id=\"player\"></div><script>var tag = document.createElement('script'); tag.src = \"http://www.youtube.com/player_api\"; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { height: '%f', width: '%f', videoId: '%@', events: { 'onReady': onPlayerReady, } }); } function onPlayerReady(event) { event.target.playVideo(); } </script></body></html>​";
    
    NSString *youtubeRequestString = [NSString stringWithFormat:videoExtractor, 2048.0f, 1536.0f, video.providerID];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:_webView];
    [self.webView loadHTMLString:youtubeRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
    
}

//deprecated AND broken
- (void)loadVimeoVideo:(Video *)video
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *vimeoExtractor = @"<html><body><center><iframe id=\"player_1\" src=\"http://player.vimeo.com/video/%@?api=1&amp;player_id=player_1\" webkit-playsinline ></iframe><script src=\"http://a.vimeocdn.com/js/froogaloop2.min.js?cdbdb\"></script><script>(function(){var vimeoPlayers = document.querySelectorAll('iframe');$f(vimeoPlayers[0]).addEvent('ready', ready);function ready(player_id) {$f(player_id).api('play');}})();</script></center></body></html>";
    
    NSString *vimeoRequestString = [NSString stringWithFormat:vimeoExtractor, video.providerID];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:_webView];
    [self.webView loadHTMLString:vimeoRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
}

- (void)loadDailyMotionVideo:(Video *)video
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *dailymotionExtractor = @"<html><body><div id=\"player\"></div><script>(function(){var e=document.createElement('script');e.async=true;e.src='http://api.dmcdn.net/all.js';var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(e, s);}());window.dmAsyncInit=function(){var player=DM.player(\"player\",{video: \"%@\", width: \"%f\", height: \"%f\", params:{api: postMessage}});player.addEventListener(\"apiready\", function(e){e.target.play();});};</script></body></html>";
    
    NSString *dailymotionRequestString = [NSString stringWithFormat:dailymotionExtractor, video.providerID, 2048.0f, 1536.0f];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:_webView];
    [self.webView loadHTMLString:dailymotionRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
}

#pragma mark - STVYouTubeExtractorDelegate

- (void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL
{
    [self processExtractedURL:videoURL];
}

- (void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error
{
    [self processFailedExtractionWithError:error];
}

#pragma mark - LBYouTubeExtractorDelegate

- (void)youTubeExtractor:(LBYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURL:(NSURL *)videoURL
{
    if (videoURL) {
        [self processExtractedURL:videoURL];
    } else {
        [self youTubeExtractor:extractor failedExtractingYouTubeURLWithError:nil];
    }

}

- (void)youTubeExtractor:(LBYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error
{
    //falling back to our extractor
    //TODO: GA - send event to google analytics
    [self destroyCurrentExtractor];
    [self stvYouTube:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
}

#pragma mark - Vimeo Extraction Results
- (void)vimeoExtractor:(YTVimeoExtractor *)extractor didSuccessfullyExtractVimeoURL:(NSURL *)videoURL
{
    [self processExtractedURL:videoURL];
}

- (void)vimeoExtractor:(YTVimeoExtractor *)extractor failedExtractingVimeoURLWithError:(NSError *)error
{
    [self processFailedExtractionWithError:error];
}

#pragma mark - Helpers for All Extractor

- (void)processExtractedURL:(NSURL *)videoURL
{
    @synchronized(self) {
        STVAssert(self.currentlyExtracting, @"expected to be extracting something!");
        STVAssert(!self.currentExtractionTimeoutTimer, @"shouldn't have extraction timeout timer");

        NSString *extractedURL = [videoURL absoluteString];

        [self cacheExtractedURL:extractedURL forVideo:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(extractedURL, NO);
        }
        self.currentlyExtracting = nil;
        [self destroyCurrentExtractor];

        [self scheduleNextExtraction];
    }
}

- (void)processFailedExtractionWithError:(NSError *)error
{
    @synchronized(self) {
        STVAssert(self.currentlyExtracting, @"expected to be extracting something!");
        STVAssert(!self.currentExtractionTimeoutTimer, @"shouldn't have extraction timeout timer");

        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(nil, YES);
        }
        self.currentlyExtracting = nil;
        [self destroyCurrentExtractor];

        [self scheduleNextExtraction];
    }
}

- (void)destroyCurrentExtractor
{
    [self destroySTVYTExtractor];
    [self destroyYTExtractor];
    [self destroyVimeoExtractor];
}

#pragma mark - WebView Extraction Results
//WebView (non YT) extraction success
- (void)processNotification:(NSNotification *)notification
{
    @synchronized(self) {
        
        if (self.currentlyExtracting && notification.userInfo && ![notification.userInfo isKindOfClass:[NSNull class]]) {
            
            // When using a webview to play video, it creates its own MPAVPlayer/Controller via some subsystem.
            // When we destroy the webview, it's possible that the multimedia subsystem keeps the AVPlayer around.
            // This can result in (at least) two bad situations...
            
            // 1) We may still see the "got video" notification for the prior video.  So we need to make sure
            // that the current extraction has actually begun...
            if(!self.webView || !self.currentWebViewDidStartLoading){
                return;
            }
            
            // 2) We may see different notifications than the desired "got video" notification (which is
            // one of many "MPAVControllerItemChangedNotification" responding to path and seems to
            // always be "MPAVControllerItemChangedNotification").
            // Not looking for the "correct" one in case it changes, so ignore the known bad ones...
            if ([notification.name isEqualToString:@"MPAVControllerItemWillChangeNotification"] ||
                [notification.name isEqualToString:@"MPAVControllerSizeDidChangeNotification"] ||
                [notification.name isEqualToString:@"MPAVControllerItemReadyToPlayNotification"]) {
                return;
            }

            NSArray *allValues = [notification.userInfo allValues];
            for (id value in allValues) {
                
                // 'path' is an instance method on 'MPAVItem'
                SEL pathSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@", @"p",@"a",@"t",@"h"]);
                
                if ([value respondsToSelector:pathSelector]) {
                    // Remove myself as an observer -- otherwise we could initiate multiple times
                    [[NSNotificationCenter defaultCenter] removeObserver:self];

                    // Remove webView
                    [self destroyWebView];
                    
                    [self.currentExtractionTimeoutTimer invalidate];
                    self.currentExtractionTimeoutTimer = nil;

                    // Get URL to playable video file
                    #pragma clang diagnostic push
                    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    NSString *extractedURL = [value performSelector:pathSelector];
                    #pragma clang diagnostic pop

                    [self cacheExtractedURL:extractedURL forVideo:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
                    extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
                    if(completionBlock){
                        completionBlock(extractedURL, NO);
                    }
                    self.currentlyExtracting = nil;

                    [self scheduleNextExtraction];
                }
            }
        }
    }
}

//WebView (non YT) extraction timeouts
- (void)extractionTimedOut:(NSTimer *)timer
{
    //prevent possible async timing issue
    if(self.currentlyExtracting && self.currentlyExtracting == timer.userInfo){
        self.currentExtractionTimeoutTimer = nil;
        
        [self destroyWebView];
        
        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(nil, YES);
        }
        self.currentlyExtracting = nil;

        [self scheduleNextExtraction];
    } else {
        DLog(@"Extraction TIMED OUT, but not the *current* extraction.  current: %@, timed out: %@", self.currentlyExtracting, timer.userInfo);
    }
}

#pragma mark - UIWebViewDelegate Methods
- (void) webViewDidFinishLoad:(UIWebView *)webView
{
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:@"WebKitCacheModelPreferenceKey"];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

#pragma mark - caching
- (NSString *)getCachedURLForVideo:(Video *)video
{
    if(self.extractedURLCache){
        NSDictionary *previousExtraction = self.extractedURLCache[video.objectID];
        if([previousExtraction[kSPVideoExtractorExtractedAtKey] timeIntervalSinceNow] < EXTRACTED_URL_TTL_S){
            //expired
            [self.extractedURLCache removeObjectForKey:video.objectID];
            return nil;
        } else {
            return previousExtraction[kSPVideoExtractorExtractedURLStringKey];
        }
    }
    return nil;
}

- (void)cacheExtractedURL:(NSString *)extractedURL forVideo:(Video *)video
{
    self.extractedURLCache[video.objectID] = @{kSPVideoExtractorExtractedURLStringKey: extractedURL,
                                               kSPVideoExtractorExtractedAtKey: [NSDate date]};
}

@end
