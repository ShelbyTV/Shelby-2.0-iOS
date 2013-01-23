//
//  SPModel.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/23/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPModel.h"
#import "SPOverlayView.h"
#import "SPVideoReel.h"
#import "SPVideoPlayer.h"

@interface SPModel ()

@property (weak, nonatomic) SPVideoPlayer <SPVideoScrubberDelegate> *videoScrubberDelegate;

@end

@implementation SPModel
@synthesize scrubberTimeObserver = _scrubberTimeObserver;
@synthesize currentVideo = _currentVideo;
@synthesize currentVideoPlayer = _currentVideoPlayer;
@synthesize videoReel = _videoReel;
@synthesize overlayView = _overlayView;
@synthesize overlayTimer = _overlayTimer;
@synthesize isAirPlayConnected = _isAirPlayConnected;
@synthesize videoScrubberDelegate = _videoScrubberDelegate;

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
- (void)cleanup
{
    [self setScrubberTimeObserver:nil];
    [self setCurrentVideo:0];
    [self setCurrentVideoPlayer:nil];
    [self setVideoReel:nil];
    [self setOverlayView:nil];
    [self setOverlayTimer:nil];
    [self setIsAirPlayConnected:NO];
    [self setVideoScrubberDelegate:nil];
}

- (void)rescheduleOverlayTimer
{
    
    if ( [self.overlayTimer isValid] )
        [self.overlayTimer invalidate];
    
    self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:[SPModel sharedInstance] selector:@selector(hideOverlay) userInfo:nil repeats:NO];
    
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
    
    //    if ( NO == [self isAirPlayConnected] ) {
    
    [UIView animateWithDuration:0.5f animations:^{
        [self.overlayView setAlpha:0.0f];
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    }];
    
    //    }
    
}

#pragma mark - SPVideoScrubberDelegate Methods
- (CMTime)elapsedDuration
{
    return [self.videoScrubberDelegate elapsedDuration];
}

- (void)setupScrubber
{
    [self.videoScrubberDelegate setupScrubber];
}

- (void)syncScrubber
{
    [self.videoScrubberDelegate syncScrubber];
}

#pragma mark - Accessor Methods
// currentVideoPlayer
- (void)setCurrentVideoPlayer:(SPVideoPlayer *)currentVideoPlayer
{
    _currentVideoPlayer = currentVideoPlayer;
    _videoScrubberDelegate = currentVideoPlayer;
}

// isAirPlayConnected
- (BOOL)isAirPlayConnected
{
    return ( 1.0f == self.videoReel.airPlayButton.alpha ) ? YES : NO;
}
@end