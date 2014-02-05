//
//  SPVideoExtractor.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoExtractor.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyErrorUtility.h"
#import "AppDelegate.h"
#import "Video.h"

@interface SPVideoExtractor () <UIWebViewDelegate>

//non web-view extractions
@property (nonatomic, strong) STVVimeoExtractor *stvVimeoExtractor;
@property (nonatomic, strong) STVYouTubeExtractor *stvYTExtractor;
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
NSString * const kSPVideoExtractorExtractedURLArrayKey = @"extractedURLArray";
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

- (void)URLsForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock highPriority:(BOOL)jumpQueue
{
    STVAssert(completionBlock, @"urlForVideo expects an extraction block");
    STVAssert(video, @"urlForVideo expects a video");
    if (!video.providerID) {
        DLog(@"*** Video without providerID... will gracefully fail immediately.  *** (%@)", video);
    }

    @synchronized(self){
        NSArray *alreadyExtractedURLs = [self getCachedURLsForVideo:video];
        if(alreadyExtractedURLs){
            if(completionBlock){
                completionBlock(alreadyExtractedURLs, nil);
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
                completionBlock(nil, nil);
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

        [self.startNextExtractionTimer invalidate];
        self.startNextExtractionTimer = nil;
        [self.currentExtractionTimeoutTimer invalidate];
        self.currentExtractionTimeoutTimer = nil;

        //fail current extraction
        if(self.currentlyExtracting){
            extraction_complete_block currentCompletionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
            [self destroyWebView];
            [self destroyCurrentExtractor];
            self.currentlyExtracting = nil;
            if(currentCompletionBlock){
                currentCompletionBlock(nil, nil);
            }
        } else {
            STVDebugAssert(self.webView == nil, @"should not have a web view w/o currently Extracting");
        }
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
            STVDebugAssert(self.webView == nil, @"webview should be nil");
            
            self.currentlyExtracting = nextExtraction;
            Video *video = self.currentlyExtracting[kSPVideoExtractorVideoKey];
            STVAssert(video, @"expected valid job w/ video");
            
            NSArray *alreadyExtractedURLs = [self getCachedURLsForVideo:video];
            if(alreadyExtractedURLs){
                //already extracted while it was waiting
                extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
                if(completionBlock){
                    completionBlock(alreadyExtractedURLs, nil);
                }
                self.currentlyExtracting = nil;
                [self scheduleNextExtraction];
                return;
                
            } else {
                if (!video.providerID) {
                    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                          action:kAnalyticsIssueVideoMissingProviderID
                                                           label:[NSString stringWithFormat:@"videoID: %@", video.videoID]];
                    [self processFailedExtractionWithError:[NSError errorWithDomain:@"SPVideoExtractor"
                                                                               code:-1
                                                                           userInfo:@{@"video": video,
                                                                                      @"reason": @"missing providerID"}]];
                    return;
                }

                //perform actual extraction
                if ([video.providerName isEqualToString:@"youtube"]) {
                    [self stvYouTube:video];
                    
                } else if ([video.providerName isEqualToString:@"vimeo"]) {
                    //the YTVimeoExtractor has stopped working.
                    //[self ytVimeo:video];
                    //Just using our in house extractor
                    [self stvVimeoVideo:video];
                
                } else if ([video.providerName isEqualToString:@"dailymotion"]) {
                    //WebView based extraction...
                    STVDebugAssert(!self.webView, @"should not have a web view already");
                    [self createWebView];
                    
                    [self loadDailyMotionVideo:video];
                    
                    STVDebugAssert(self.currentExtractionTimeoutTimer == nil, @"shouldn't have a current extraction timeout timer");
                    self.currentExtractionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                                                          target:self
                                                                                        selector:@selector(extractionTimedOut:)
                                                                                        userInfo:self.currentlyExtracting
                                                                                         repeats:NO];
                } else {
                    STVDebugAssert(NO, @"Invalid video provider");
                    [self cancelCurrentExtraction];
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
    STVDebugAssert(self.webView == webView, @"we should only have one web view at a time");
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

- (void)destroySTVVimeoExtractor
{
    [self.stvVimeoExtractor stopExtracting];
    self.stvVimeoExtractor.delegate = nil;
    self.stvVimeoExtractor = nil;
}

- (void)destroySTVYTExtractor
{
    [self.stvYTExtractor stopExtracting];
    self.stvYTExtractor.delegate = nil;
    self.stvYTExtractor = nil;
}

- (void)destroyVimeoExtractor
{
    //has no cancel
    self.vimeoExtractor.delegate = nil;
    self.vimeoExtractor = nil;
}

- (void)stvVimeoVideo:(Video *)video
{
    STVAssert(video, @"must have a video to extract");
    //HLS allows client to select proper quality, and our extractor will fallback if HLS isn't available
    self.stvVimeoExtractor = [[STVVimeoExtractor alloc] initWithID:video.providerID quality:STVVimeoVideoQualityHLS];
    self.stvVimeoExtractor.delegate = self;
    [self.stvVimeoExtractor startExtracting];
}

- (void)stvYouTube:(Video *)video
{
    STVAssert(video, @"must have a video to extract");
    STVYouTubeVideoQuality quality;
    if (DEVICE_IPAD) {
        quality = STVYouTubeVideoQualityHD720;
    } else {
        quality = STVYouTubeVideoQualityMedium;
    }
    self.stvYTExtractor = [[STVYouTubeExtractor alloc] initWithID:video.providerID quality:quality];
    self.stvYTExtractor.delegate = self;
    [self.stvYTExtractor startExtracting];
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

#pragma mark - STVVimeoExtractorDelegate

- (void)stvVimeoExtractor:(STVVimeoExtractor *)extractor didSuccessfullyExtractVimeoURL:(NSURL *)videoURL
{
    NSParameterAssert(videoURL);
    [self processExtractedURLs:@[videoURL]];
}

- (void)stvVimeoExtractor:(STVVimeoExtractor *)extractor failedExtractingVimeoURLWithError:(NSError *)error
{
    [self processFailedExtractionWithError:error];
}

#pragma mark - STVYouTubeExtractorDelegate

- (void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor didSuccessfullyExtractYouTubeURLs:(NSArray *)videoURLsArray
{
    [self processExtractedURLs:videoURLsArray];
}

- (void)stvYouTubeExtractor:(STVYouTubeExtractor *)extractor failedExtractingYouTubeURLWithError:(NSError *)error
{
    [self processFailedExtractionWithError:error];
}

#pragma mark - Vimeo Extraction Results
- (void)vimeoExtractor:(YTVimeoExtractor *)extractor didSuccessfullyExtractVimeoURL:(NSURL *)videoURL
{
    NSParameterAssert(videoURL);
    [self processExtractedURLs:@[videoURL]];
}

- (void)vimeoExtractor:(YTVimeoExtractor *)extractor failedExtractingVimeoURLWithError:(NSError *)error
{
    [self processFailedExtractionWithError:error];
}

#pragma mark - Helpers for All Extractor

- (void)processExtractedURLs:(NSArray *)videoURLs
{
    @synchronized(self) {
        if (!self.currentlyExtracting) {
            STVDebugAssert(self.currentlyExtracting, @"expected to be extracting something!");
            return;
        }
        STVDebugAssert(!self.currentExtractionTimeoutTimer, @"shouldn't have extraction timeout timer");

        [self cacheExtractedURLs:videoURLs forVideo:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(videoURLs, nil);
        }
        [self destroyCurrentExtractor];
        self.currentlyExtracting = nil;

        [self scheduleNextExtraction];
    }
}

- (void)processFailedExtractionWithError:(NSError *)error
{
    @synchronized(self) {
        if (!self.currentlyExtracting) {
            STVDebugAssert(self.currentlyExtracting, @"expected to be extracting something!");
            return;
        }
        STVDebugAssert(!self.currentExtractionTimeoutTimer, @"shouldn't have extraction timeout timer");

        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if (completionBlock) {
            if ([ShelbyErrorUtility isConnectionError:error]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNoInternetConnectionNotification object:nil];
            }
            completionBlock(nil, error);
        }
        [self destroyCurrentExtractor];
        self.currentlyExtracting = nil;


        [self scheduleNextExtraction];
    }
}

- (void)destroyCurrentExtractor
{
    [self destroySTVVimeoExtractor];
    [self destroySTVYTExtractor];
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

                    [self cacheExtractedURLs:@[extractedURL] forVideo:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
                    extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
                    if(completionBlock){
                        completionBlock(@[extractedURL], nil);
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
    @synchronized(self) {
        //prevent possible async timing issue
        if(self.currentlyExtracting && self.currentlyExtracting == timer.userInfo){
            self.currentExtractionTimeoutTimer = nil;
            
            extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
            [self destroyWebView];
            [self destroyCurrentExtractor];
            self.currentlyExtracting = nil;
            if(completionBlock){
                completionBlock(nil, [NSError errorWithDomain:@"SPVideoExtractor"
                                                         code:-1
                                                     userInfo:@{@"reason": @"timed out"}]);
            }

            [self scheduleNextExtraction];
        } else {
            DLog(@"Extraction TIMED OUT, but not the *current* extraction.  current: %@, timed out: %@", self.currentlyExtracting, timer.userInfo);
        }
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
- (NSArray *)getCachedURLsForVideo:(Video *)video
{
    if(self.extractedURLCache){
        NSDictionary *previousExtraction = self.extractedURLCache[video.objectID];
        if([previousExtraction[kSPVideoExtractorExtractedAtKey] timeIntervalSinceNow] < EXTRACTED_URL_TTL_S){
            //expired
            [self.extractedURLCache removeObjectForKey:video.objectID];
            return nil;
        } else {
            return previousExtraction[kSPVideoExtractorExtractedURLArrayKey];
        }
    }
    return nil;
}

- (void)cacheExtractedURLs:(NSArray *)extractedURLs forVideo:(Video *)video
{
    self.extractedURLCache[video.objectID] = @{kSPVideoExtractorExtractedURLArrayKey: extractedURLs,
                                               kSPVideoExtractorExtractedAtKey: [NSDate date]};
}

@end
