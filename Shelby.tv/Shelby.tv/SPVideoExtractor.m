//
//  SPVideoExtractor.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/2/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoExtractor.h"
#import "Video.h"

@interface SPVideoExtractor () <UIWebViewDelegate>

@property (strong, nonatomic) NSMutableArray *videoQueue;
@property (strong, nonatomic) UIWebView *webView;
@property (assign, nonatomic) BOOL isExtracting;
@property (strong, nonatomic) NSTimer *nextExtractionTimer;
@property (strong, nonatomic) NSTimer *currentExtractionTimer;

- (NSManagedObjectContext*)context;
- (void)extractNextVideoFromQueue;
- (void)createWebView;
- (void)destroyWebView;
- (void)loadYouTubeVideo:(Video *)video;
- (void)loadVimeoVideo:(Video *)video;
- (void)loadDailyMotionVideo:(Video *)video;
- (void)processNotification:(NSNotification *)notification;
- (void)timerExpired;

@end

@implementation SPVideoExtractor
@synthesize videoQueue = _videoQueue;
@synthesize webView = _webView;
@synthesize isExtracting = _isExtracting;
@synthesize nextExtractionTimer = _nextExtractionTimer;
@synthesize currentExtractionTimer = _currentExtractionTimer;

#pragma mark - Singleton Methods
+ (SPVideoExtractor*)sharedInstance
{    
    static SPVideoExtractor *sharedInstance = nil;
    static dispatch_once_t extractorToken = 0;
    dispatch_once(&extractorToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

#pragma mark - Public Methods
- (void)queueVideo:(Video *)video
{
    @synchronized(self) {
        
        // If queue is empty
        if ( ![self videoQueue] ) {
            self.videoQueue = [[NSMutableArray alloc] init];;
        }
        
        [self.videoQueue addObject:video];
        [self extractNextVideoFromQueue];
        
    }
}

- (void)emptyQueue
{
    if ( [self.videoQueue count] ) {
        
        for ( NSUInteger i = 1; i < [self.videoQueue count]; i++ ) {
            [self.videoQueue removeObjectAtIndex:i];
        }
        
    }
}

- (void)cancelRemainingExtractions
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setIsExtracting:NO];
    [self.nextExtractionTimer invalidate];
    [self.videoQueue removeAllObjects];
    [self destroyWebView];
    
    DLog(@"Remaining Extractions Cancelled!");
}

#pragma mark - Private Methods
- (NSManagedObjectContext*)context
{
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    
    return [appDelegate context];
}

- (void)extractNextVideoFromQueue
{
    if ( ![self isExtracting] && [self.videoQueue count] ) {
        
        NSManagedObjectContext *context = [self context];
        NSManagedObjectID *objectID = [[self.videoQueue objectAtIndex:0] objectID];
        Video *video = (Video*)[context existingObjectWithID:objectID error:nil];
        [self setIsExtracting:YES];
        [self createWebView];
        
        if ( [video.providerName isEqualToString:@"youtube"] ) {
            
            [self loadYouTubeVideo:video];
            
        } else if ( [video.providerName isEqualToString:@"vimeo"] ) {
            
            [self loadVimeoVideo:video];
            
        } else if ( [video.providerName isEqualToString:@"dailymotion"] ) {
            
            [self loadDailyMotionVideo:video];
            
        }

        self.currentExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:20.0f target:self selector:@selector(timerExpired) userInfo:nil repeats:NO];
        
    }
}

- (void)createWebView
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    CGRect frame = CGRectMake(0.0f, 0.0f, 1024.0f, 768.0f);
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
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:self.webView];
    [self.webView loadHTMLString:youtubeRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
    
}

- (void)loadVimeoVideo:(Video *)video
{
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *vimeoExtractor = @"<html><body><center><iframe id=\"player_1\" src=\"http://player.vimeo.com/video/%@?api=1&amp;player_id=player_1\" webkit-playsinline ></iframe><script src=\"http://a.vimeocdn.com/js/froogaloop2.min.js?cdbdb\"></script><script>(function(){var vimeoPlayers = document.querySelectorAll('iframe');$f(vimeoPlayers[0]).addEvent('ready', ready);function ready(player_id) {$f(player_id).api('play');}})();</script></center></body></html>";
    
    NSString *vimeoRequestString = [NSString stringWithFormat:vimeoExtractor, video.providerID];
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:self.webView];
    [self.webView loadHTMLString:vimeoRequestString baseURL:[NSURL URLWithString:@"http://shelby.tv"]];
    
}

- (void)loadDailyMotionVideo:(Video *)video
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(processNotification:) name:nil object:nil];
    
    static NSString *dailymotionExtractor = @"<html><body><div id=\"player\"></div><script>(function(){var e=document.createElement('script');e.async=true;e.src='http://api.dmcdn.net/all.js';var s=document.getElementsByTagName('script')[0];s.parentNode.insertBefore(e, s);}());window.dmAsyncInit=function(){var player=DM.player(\"player\",{video: \"%@\", width: \"%f\", height: \"%f\", params:{api: postMessage}});player.addEventListener(\"apiready\", function(e){e.target.play();});};</script></body></html>";
    
    NSString *dailymotionRequestString = [NSString stringWithFormat:dailymotionExtractor, video.providerID, 2048.0f, 1536.0f];
    
    DLog(@"%@", dailymotionRequestString);
    
    AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    [appDelegate.window addSubview:self.webView];
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
                    [[NSURLCache sharedURLCache] removeAllCachedResponses];
                    
                    // Get videoURL to playable video file
                    NSString *extractedURL = [value performSelector:pathSelector];
                    
                    [self.currentExtractionTimer invalidate];
                    
                    if ( 0 == [self.videoQueue count] ) {
                        
                        // Do nothing if the HOME button is pushed in SPVideoReel while a video was being processed.
                        
                    } else {
                        
                        // Update Core Data video object
                        NSManagedObjectContext *context = [self context];
                        NSManagedObjectID *objectID = [[self.videoQueue objectAtIndex:0] objectID];
                        Video *video = (Video*)[context existingObjectWithID:objectID error:nil];
                        [video setValue:extractedURL forKey:kCoreDataVideoExtractedURL];
                       
                        // Saved updated Core Data video entry, and post notification for SPVideoPlayer object
                        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_VideoExtracted];
                        [dataUtility setVideoID:video.videoID];
                        [dataUtility saveContext:context];
                        
                        // Reset variables for next search
                        [self.videoQueue removeObjectAtIndex:0];
                        [self setIsExtracting:NO];
                        
                        self.nextExtractionTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(extractNextVideoFromQueue) userInfo:nil repeats:NO];

                    }
                }
            }
        }
    }
}

- (void)timerExpired
{
    [self setIsExtracting:NO];
    [self.nextExtractionTimer invalidate];
    [self.currentExtractionTimer invalidate];
    [self destroyWebView];
    
    [self extractNextVideoFromQueue];
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