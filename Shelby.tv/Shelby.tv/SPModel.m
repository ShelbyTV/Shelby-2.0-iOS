//
//  SPModel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/23/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "SPVideoExtractor.h"
#import "SPOverlayView.h"
#import "SPVideoReel.h"
#import "SPVideoPlayer.h"

@interface SPModel ()

@property (nonatomic) NSMutableArray *loadedVideoPlayers;
@property (weak, nonatomic) SPVideoPlayer <SPVideoScrubberDelegate> *videoScrubberDelegate;

@end

@implementation SPModel
@synthesize scrubberTimeObserver = _scrubberTimeObserver;
@synthesize numberOfVideos = _numberOfVideos;
@synthesize currentVideo = _currentVideo;
@synthesize currentVideoPlayer = _currentVideoPlayer;
@synthesize videoExtractor = _videoExtractor;
@synthesize videoReel = _videoReel;
@synthesize overlayView = _overlayView;
@synthesize overlayTimer = _overlayTimer;
@synthesize videoScrubberDelegate = _videoScrubberDelegate;
@synthesize loadedVideoPlayers = _loadedVideoPlayers;

#pragma mark - Singleton Methods
+ (SPModel*)sharedInstance
{
    static SPModel *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

#pragma mark - Public Methods
+ (SPVideoExtractor*)videoExtractor
{
    return [SPVideoExtractor sharedInstance];
}

- (void)storeVideoPlayer:(SPVideoPlayer *)player
{
    
    if ( ![self loadedVideoPlayers] )
        self.loadedVideoPlayers = [[NSMutableArray alloc] init];
    
    [self.loadedVideoPlayers addObject:player];
    
    if ( [self.loadedVideoPlayers count] > 2 ) {
        
        DLog(@"Count: %d", [self.loadedVideoPlayers count] );
        
        SPVideoPlayer *oldestPlayer = (SPVideoPlayer*)[self.loadedVideoPlayers objectAtIndex:0];
        
        if ( oldestPlayer != self.currentVideoPlayer ) {
         
            [oldestPlayer resetPlayer];
            [self.loadedVideoPlayers removeObject:oldestPlayer];
            
        }
    }
}

- (void)teardown
{
    [self.videoExtractor cancelRemainingExtractions];
    [self setScrubberTimeObserver:nil];
    [self setNumberOfVideos:0];
    [self setCurrentVideo:0];
    [self setCurrentVideoPlayer:nil];
    [self setVideoReel:nil];
    [self setOverlayView:nil];
    [self setOverlayTimer:nil];
    [self setVideoScrubberDelegate:nil];
}

- (void)rescheduleOverlayTimer
{
    
    if ( [self.overlayTimer isValid] )
        [self.overlayTimer invalidate];
    
    
    if ( [self.videoReel.airPlayButton state] != 4 ) { // Keep SPVideoOverlay visible if airPlayIsConnected
    
        self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                             target:[SPModel sharedInstance]
                                                           selector:@selector(hideOverlay)
                                                           userInfo:nil
                                                            repeats:NO];
    }

}

- (void)toggleOverlay
{
    
    if ( self.overlayView.alpha < 1.0f ) {
        
        [self showOverlay];
        
    } else {
        
        [self hideOverlay];
    }
}

- (void)showOverlay
{
    [UIView animateWithDuration:0.5f animations:^{
        [self.overlayView setAlpha:1.0f];
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    }];
}

- (void)hideOverlay
{
    
    [UIView animateWithDuration:0.5f animations:^{
        [self.overlayView setAlpha:0.0f];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    }];

    
}

#pragma mark - Accessor Methods
// currentVideoPlayer Setter
- (void)setCurrentVideoPlayer:(SPVideoPlayer *)currentVideoPlayer
{
    _currentVideoPlayer = currentVideoPlayer;
    _videoScrubberDelegate = currentVideoPlayer;
}

// videoExtractor Getter
- (SPVideoExtractor*)videoExtractor
{
    return [SPVideoExtractor sharedInstance];
}


@end