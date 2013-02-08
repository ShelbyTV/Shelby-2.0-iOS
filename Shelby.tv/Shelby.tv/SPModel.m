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

@end

@implementation SPModel

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

- (void)destroyModel
{
    [self setNumberOfVideos:0];
    [self setCurrentVideo:0];
    [self setVideoReel:nil];
    [self setOverlayView:nil];
    [self setOverlayTimer:nil];
    [self setLoadedVideoPlayers:nil];
    [self setCurrentVideoPlayer:nil];
}

- (void)rescheduleOverlayTimer
{
    
    if ( [self.overlayTimer isValid] )
        [self.overlayTimer invalidate];
    
    
    if ( [self.videoReel.airPlayButton state] != 4 ) { // Keep SPVideoOverlay visible if airPlayIsConnected
    
        self.overlayTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f
                                                             target:self.overlayView
                                                           selector:@selector(hideOverlay)
                                                           userInfo:nil
                                                            repeats:NO];
    }

}

@end
