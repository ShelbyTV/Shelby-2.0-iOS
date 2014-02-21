//
//  ShelbyAirPlayController.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPVideoPlayer.h"
#import "VideoControlsViewController.h"

@protocol ShelbyAirPlayControllerDelegate;

@interface ShelbyAirPlayController : NSObject <SPVideoPlayerDelegate>
@property (nonatomic, weak) id<ShelbyAirPlayControllerDelegate> delegate;
@property (nonatomic, weak) VideoControlsViewController *videoControlsVC;

- (BOOL)isAirPlayActive;
- (void)playEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel;
- (void)pauseCurrentPlayer;
- (void)playCurrentPlayer;
- (void)beginScrubbing;
- (void)scrubCurrentPlayerTo:(CGFloat)percent;
- (void)endScrubbing;

- (void)checkForExistingScreenAndInitializeIfPresent;
@end

@protocol ShelbyAirPlayControllerDelegate <NSObject>
- (void)airPlayControllerDidBeginAirPlay:(ShelbyAirPlayController *)airPlayController;
- (void)airPlayControllerDidEndAirPlay:(ShelbyAirPlayController *)airPlayController;
- (void)airPlayControllerShouldAutoadvance:(ShelbyAirPlayController *)airPlayController;
@end