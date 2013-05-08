//
//  SPVideoExtractor.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoExtractor.h"
#import "Video.h"

@interface SPVideoExtractor () <UIWebViewDelegate>

@property (nonatomic) UIWebView *webView;
@property (nonatomic) NSTimer *startNextExtractionTimer;
@property (nonatomic) NSTimer *currentExtractionTimeoutTimer;
// array of {kSPVideoExtractorVideoKey: Video*, kSPVideoExtractorBlockKey: extraction_complete_block} waiting to be processed
@property (nonatomic) NSMutableArray *extractionQueue;
// {kSPVideoExtractorVideoKey: Video*, kSPVideoExtractorBlockKey: extraction_complete_block} currently processing
@property (nonatomic, strong) NSDictionary *currentlyExtracting;
// array of {kSPVideoExtractorVideoObjectIDKey: Video*, kSPVideoExtractorExtractedURLStringKey: NSString*, kSPVideoExtractorExtractedAtKey: NSDate*}
// Videosalready processed, 
@property (nonatomic) NSMutableDictionary *extractedURLCache;

- (void)extractNextVideoFromQueue;
- (void)createWebView;
- (void)destroyWebView;
- (void)loadYouTubeVideo:(Video *)video;
- (void)loadVimeoVideo:(Video *)video;
- (void)loadDailyMotionVideo:(Video *)video;
- (void)processNotification:(NSNotification *)notification;
- (void)extractionTimedOut:(NSTimer *)timer;

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

#pragma mark - Public Methods

- (void)URLForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock highPriority:(BOOL)queueNext
{
    @synchronized(self){
        if (!self.extractionQueue) {
            self.extractionQueue = [@[] mutableCopy];
        }
        
        NSString *alreadyExtractedURL = [self getCachedURLForVideo:video];
        if(alreadyExtractedURL){
//            DLog(@"Already extracted for video: %@", video.videoID);
            if(completionBlock){
                completionBlock(alreadyExtractedURL);
            }
        } else {
            NSMutableDictionary *extractionDict = [@{kSPVideoExtractorVideoKey: video} mutableCopy];
            if(completionBlock){
                extractionDict[kSPVideoExtractorBlockKey] = completionBlock;
            }
            
            if(queueNext){
//                DLog(@"Queuing for HIGH Priority extraction: %@", video.videoID);
                [self.extractionQueue insertObject:extractionDict atIndex:0];
                //djs TODO: cancel current extraction here (handle timer properly)
            } else {
//                DLog(@"Queuing for low priority extraction: %@", video.videoID);
                [self.extractionQueue addObject:extractionDict];
            }
            [self scheduleNextExtraction];
        }
    }
}

- (void)warmCacheForVideo:(Video *)video
{
    if(!self.extractionQueue || [self.extractionQueue count] < 5){
        [self URLForVideo:video usingBlock:nil highPriority:NO];
    }
}

- (void)scheduleNextExtraction
{
    if(!self.startNextExtractionTimer){
//        DLog(@"scheduled next extraction timer...");
        self.startNextExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:0.75
                                                                         target:self
                                                                       selector:@selector(extractNextVideoFromQueue)
                                                                       userInfo:nil
                                                                        repeats:NO];
    } else {
//        DLog(@"next extraction timer already scheduled");
    }
}

- (void)cancelRemainingExtractions
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.startNextExtractionTimer invalidate];
    self.startNextExtractionTimer = nil;
    [self.currentExtractionTimeoutTimer invalidate];
    self.currentExtractionTimeoutTimer = nil;
    
    //fail all pending extractions
    if(self.currentlyExtracting){
        extraction_complete_block currentCompletionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(currentCompletionBlock){
            currentCompletionBlock(nil);
        }
    }
    self.currentlyExtracting = nil;
    for (NSDictionary *queuedExtraction in self.extractionQueue) {
        extraction_complete_block completionBlock = queuedExtraction[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(nil);
        }
    }
    [self.extractionQueue removeAllObjects];
    
    [self destroyWebView];
//    DLog(@"Remaining Extractions Cancelled!");
}

#pragma mark - Private Methods

- (void)extractNextVideoFromQueue
{
    self.startNextExtractionTimer = nil;
    
    if (!self.currentlyExtracting && [self.extractionQueue count]) {
//        DLog(@"setting up a new extraction...");
        self.currentlyExtracting = self.extractionQueue[0];
        [self.extractionQueue removeObjectAtIndex:0];
        Video *video = self.currentlyExtracting[kSPVideoExtractorVideoKey];
        
        if (!video) {
            extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
            if(completionBlock){
                completionBlock(nil);
            }
            self.currentlyExtracting = nil;
            [self scheduleNextExtraction];
            return;
        }
        
        NSString *alreadyExtractedURL = [self getCachedURLForVideo:video];
        if(alreadyExtractedURL){
            //already extracted while it was waiting
//            DLog(@"Already extracted for video: %@", video.videoID);
            extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
            if(completionBlock){
                completionBlock(alreadyExtractedURL);
            }
            self.currentlyExtracting = nil;
            [self scheduleNextExtraction];
            return;
        } else {
            //perform actual extraction
            [self createWebView];
            if ([video.providerName isEqualToString:@"youtube"]) {
                [self loadYouTubeVideo:video];
            } else if ([video.providerName isEqualToString:@"vimeo"]) {
                [self loadVimeoVideo:video];
            } else if ([video.providerName isEqualToString:@"dailymotion"]) {
                [self loadDailyMotionVideo:video];
            }

            self.currentExtractionTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                                                  target:self
                                                                                selector:@selector(extractionTimedOut:)
                                                                                userInfo:self.currentlyExtracting
                                                                                 repeats:NO];
        }
    } else {
//        DLog(@"********* not setting up extraction (queue depth: %lu) ***********", (unsigned long)[self.extractionQueue count]);
    }
}

- (void)createWebView
{
    CGRect frame = CGRectMake(0.0f, 0.0f, kShelbySPVideoWidth, kShelbySPVideoHeight);
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(frame.size.width/2.0f, frame.size.height/2.0f, 2.0f, 2.0f)];
    self.webView.allowsInlineMediaPlayback = YES;
    self.webView.mediaPlaybackRequiresUserAction = NO;
    self.webView.mediaPlaybackAllowsAirPlay = YES;
    self.webView.hidden = YES;
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
}

- (void)destroyWebView
{
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView stopLoading];
    [self.webView setDelegate:nil];
    [self.webView removeFromSuperview];
    [self setWebView:nil];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}

- (void)loadYouTubeVideo:(Video *)video
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *videoExtractor = @"<html><body><div id=\"player\"></div><script>var tag = document.createElement('script'); tag.src = \"http://www.youtube.com/player_api\"; var firstScriptTag = document.getElementsByTagName('script')[0]; firstScriptTag.parentNode.insertBefore(tag, firstScriptTag); var player; function onYouTubePlayerAPIReady() { player = new YT.Player('player', { height: '%f', width: '%f', videoId: '%@', events: { 'onReady': onPlayerReady, } }); } function onPlayerReady(event) { event.target.playVideo(); } </script></body></html>​";
    
    NSString *youtubeRequestString = [NSString stringWithFormat:videoExtractor, 2048.0f, 1536.0f, video.providerID];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:_webView];
    [self.webView loadHTMLString:youtubeRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
    
}

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

- (void)processNotification:(NSNotification *)notification
{
    @synchronized(self) {
        
        if ( notification.userInfo && ![notification.userInfo isKindOfClass:[NSNull class]] ) {
            
            NSArray *allValues = [notification.userInfo allValues];
            for (id value in allValues) {
                
                // 'path' is an instance method on 'MPAVItem'
                SEL pathSelector = NSSelectorFromString([NSString stringWithFormat:@"%@%@%@%@", @"p",@"a",@"t",@"h"]);
                
                if ([value respondsToSelector:pathSelector]) {
//                    DLog(@"Great extraction success!");

                    // Remove myself as an observer -- otherwise we could initiate 'playVideo' multiple times, slowing down video display
                    [[NSNotificationCenter defaultCenter] removeObserver:self];

                    // Remove webView
                    [self destroyWebView];
                    
                    [self.currentExtractionTimeoutTimer invalidate];
                    self.currentExtractionTimeoutTimer = nil;

                    // Get videoURL to playable video file
                    #pragma GCC diagnostic push
                    #pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
                    NSString *extractedURL = [value performSelector:pathSelector];
                    #pragma GCC diagnostic pop

                    [self cacheExtractedURL:extractedURL forVideo:self.currentlyExtracting[kSPVideoExtractorVideoKey]];
                    extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
                    if(completionBlock){
                        completionBlock(extractedURL);
                    }
                    self.currentlyExtracting = nil;

                    [self scheduleNextExtraction];
                }
            }
        }
    }
}

- (void)extractionTimedOut:(NSTimer *)timer
{
    //prevent possible async timing issue
    if(self.currentlyExtracting && self.currentlyExtracting == timer.userInfo){
//        DLog(@"Extraction TIMED OUT, cancelling current extraction...");
        self.currentExtractionTimeoutTimer = nil;
        
        [self destroyWebView];
        
        extraction_complete_block completionBlock = self.currentlyExtracting[kSPVideoExtractorBlockKey];
        if(completionBlock){
            completionBlock(nil);
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
    if(!self.extractedURLCache){
        self.extractedURLCache = [[NSMutableDictionary alloc] init];
    }
    self.extractedURLCache[video.objectID] = @{kSPVideoExtractorExtractedURLStringKey: extractedURL,
                                               kSPVideoExtractorExtractedAtKey: [NSDate date]};
}

@end
