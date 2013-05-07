//
//  SPVideoExtractor.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

#import "SPVideoExtractor.h"
#import "Video.h"
//djs this has no reason to know about the API
//#import "ShelbyAPIClient.h"

@interface SPVideoExtractor () <UIWebViewDelegate>

@property (nonatomic) NSMutableArray *videoQueue;
@property (nonatomic) UIWebView *webView;
@property (nonatomic) NSTimer *nextExtractionTimer;
@property (nonatomic) NSTimer *currentExtractionTimer;
// KP KP remove isEx
@property (assign, nonatomic) BOOL isExtracting;
@property (nonatomic, strong) NSDictionary *currentlyExtracting;

//djs we shouldn't need a fucking context
//- (NSManagedObjectContext *)context;
- (void)extractNextVideoFromQueue;
- (void)createWebView;
- (void)destroyWebView;
- (void)loadYouTubeVideo:(Video *)video;
- (void)loadVimeoVideo:(Video *)video;
- (void)loadDailyMotionVideo:(Video *)video;
- (void)processNotification:(NSNotification *)notification;
- (void)extractionTimerExpired:(NSTimer *)timer;

@end

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
//djs deprecated, now use URLForVideo:usingBlock:
//- (void)queueVideo:(Video *)video
//{
//    @synchronized(self) {
//        
//        // If queue is empty
//        if ( ![self videoQueue] ) {
//            self.videoQueue = [@[] mutableCopy];
//        }
//        
//        if (video) {
//            [self.videoQueue addObject:video];
//        }
//        
//        [self extractNextVideoFromQueue];
//        
//    }
//}

- (void)URLForVideo:(Video *)video usingBlock:(extraction_complete_block)completionBlock
{
    @synchronized(self){
        if (!self.videoQueue) {
            self.videoQueue = [@[] mutableCopy];
        }
        // KP KP: TODO: make the keys externs
        [self.videoQueue addObject:@{@"video" : video, @"block" : completionBlock}];
        
        self.nextExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(extractNextVideoFromQueue) userInfo:nil repeats:NO];
        
        //TODO: store the video and completionBlock on videoQueue
    }
}

- (void)cancelRemainingExtractions
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.isExtracting = NO;
    [self.nextExtractionTimer invalidate];
    [self.videoQueue removeAllObjects];
    [self destroyWebView];
    
    DLog(@"Remaining Extractions Cancelled!");
}

#pragma mark - Private Methods
- (void)extractNextVideoFromQueue
{
    if (!self.currentlyExtracting && [self.videoQueue count]) {
        //djs we should be able to use the video handed to us w/o any issue...
        self.currentlyExtracting = self.videoQueue[0];
        [self.videoQueue removeObjectAtIndex:0];
        Video *video = self.currentlyExtracting[@"video"];
        // KP KP: TODO: move to a method
        if (!video) {
            extraction_complete_block completionBlock = self.currentlyExtracting[@"block"];
            completionBlock(nil);
            self.currentlyExtracting = nil;
            // TODO: user perform selector instead
            [self extractNextVideoFromQueue];
            return;
        }

        [self createWebView];
        
        //djs is there not a nice switch statement for this?
        if ([video.providerName isEqualToString:@"youtube"]) {
            [self loadYouTubeVideo:video];
        } else if ([video.providerName isEqualToString:@"vimeo"]) {
            [self loadVimeoVideo:video];
        } else if ([video.providerName isEqualToString:@"dailymotion"]) {
            [self loadDailyMotionVideo:video];
        }

        //djs don't think we need the userInfo
        self.currentExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:10.0f target:self selector:@selector(extractionTimerExpired:) userInfo:[video videoID] repeats:NO];
        
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
                    
                    // Remove myself as an observer -- otherwise we could initiate 'playVideo' multiple times, slowing down video display
                    [[NSNotificationCenter defaultCenter] removeObserver:self];
                    
                    // Remove webView
                    [self destroyWebView];
                    
                    // Get videoURL to playable video file
                    // hard to remove warning, since 'value' is an instance of a private class - MPAVItem.
                    NSString *extractedURL = [value performSelector:pathSelector];
                    
                    [self.currentExtractionTimer invalidate];
                    [self setCurrentExtractionTimer:nil];
//                    if ( 0 == [self.videoQueue count] ) {
                        
                        // Do nothing if the HOME button is pushed in SPVideoReel while a video was being processed.
                        
//                    } else {
                    
                        // Update Core Data video object
//                        NSManagedObjectContext *context = [self context];
//                        NSManagedObjectID *objectID = [(self.videoQueue)[0] objectID];
//                        Video *video = (Video *)[context existingObjectWithID:objectID error:nil];
                        //djs don't need all that core data context sillyness, SO LONG AS we were given a proper ManagedObject
                        //actually, why are we putting this in the ManagedObject at all???
                        //we just hit the block now and let somebody else deal with it!
//                        Video *video = self.videoQueue[0];
//                        [video setValue:extractedURL forKey:kShelbyCoreDataVideoExtractedURL];
                       
                        // Saved updated Core Data video entry, and post notification for SPVideoPlayer object
//                        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_VideoExtracted];
//                        [dataUtility setVideoID:video.videoID];
//                        [dataUtility saveContext:context];
                        //djs we can just save the fucking video like normal
//                        [video.managedObjectContext save:nil];
                        
                        //djs DataRequestType_VideoExtracted had side effects, posting a notification:
//                        // Post notification if SPVideoReel object is available
//                        NSDictionary *videoDictionary = @{kShelbySPCurrentVideo: video};
//                        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPVideoExtracted
//                                                                            object:nil
//                                                                          userInfo:videoDictionary];
                        //djs this is the notification the SPVideoPlayer listened for
                        

                        // Reset variables for next search
//                        [self.videoQueue removeObjectAtIndex:0];
//                        [self setIsExtracting:NO];
                    
                    extraction_complete_block completionBlock = self.currentlyExtracting[@"block"];
                    completionBlock(extractedURL);
                    self.currentlyExtracting = nil;
//                        
                    self.nextExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:0.75 target:self selector:@selector(extractNextVideoFromQueue) userInfo:nil repeats:NO];

//                    }
                }
            }
        }
    }
}

- (void)extractionTimerExpired:(NSTimer *)timer
{
    
//    if ( [self.videoQueue count] ) {

        // TODO (comment via Arthur to Keren): I think this should only work for logged-in users, since the markUnplayableVideo: method involves the use of an auth_token. Double check to see if auth_token is necessary.
        
        // TODO: not marking unplayable as it might be playable on the web. Need to have seperate properties for web and mobile

//        NSManagedObjectContext *context = [self context];
//        
//        NSManagedObjectID *objectID = [(self.videoQueue)[0] objectID];
//        if (objectID) {
//            Video *video = (Video *)[context existingObjectWithID:objectID error:nil];
//            [ShelbyAPIClient markUnplayableVideo:[video videoID]];
//        }
        
        //djs TODO: call the block with nil

        // 'if' conditional shouldn't be necessary, since _videoQueue should have at least one item, the one that failed to be extracted
//        [self.videoQueue removeObjectAtIndex:0];
//        
//    }
    
    [self.nextExtractionTimer invalidate];
    [self.currentExtractionTimer invalidate];
    [self destroyWebView];

    
    extraction_complete_block completionBlock = self.currentlyExtracting[@"block"];
    completionBlock(nil);
    self.currentlyExtracting = nil;
    
    //TODO: do this w/ timer
    [self extractNextVideoFromQueue];
    return;
    

//    id userInfo = [timer userInfo];
 
    // Scroll to next video, which subsequently queues the next video for extraction
    //djs XXX the SPVideoExtractor SHOULD NOT CARE about video playback.
    //  it should just notify whomever cares tha extraction failed
//    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbySPLoadVideoAfterUnplayableVideo object:userInfo];

    
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

@end
