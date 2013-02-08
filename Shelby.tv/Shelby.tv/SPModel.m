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

- (void)storeVideoPlayer:(SPVideoPlayer *)player
{
    
    if ( ![self loadedVideoPlayers] ) {
        self.loadedVideoPlayers = [@[] mutableCopy];
    }
    
    // Add newly loaded SPVideoPlayer to list of SPVideoPlayers
    [self.loadedVideoPlayers addObject:player];
    
    // If screen is retina (e.g., iPad 3 or great), allow 6 videos. Otherwise, allow only 3 videos to be stored
    NSUInteger maxVideosAllowed = ( [UIScreen isRetina] ) ? 6 : 3;
    
    if ( [self.loadedVideoPlayers count] > maxVideosAllowed ) { // If more than X number of videos are loaded, unload the older videos in the list
        
        DLog(@"Count: %d", [self.loadedVideoPlayers count] );
        
        SPVideoPlayer *oldestPlayer = (SPVideoPlayer*)(self.loadedVideoPlayers)[0];
        
        if ( oldestPlayer != self.currentVideoPlayer ) { // If oldestPlayer isn't currently being played, remove it
         
            [oldestPlayer resetPlayer];
            [self.loadedVideoPlayers removeObject:oldestPlayer];

        } else { // If oldestPlayer is being played, remove next-oldest video
            
            if ( [self.loadedVideoPlayers count] > 1) {
            
                SPVideoPlayer *nextOldestPlayer = (SPVideoPlayer*)(self.loadedVideoPlayers)[1];
                [self.loadedVideoPlayers removeObject:nextOldestPlayer];
                
            }
        }
    }
}

- (void)destroy
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
