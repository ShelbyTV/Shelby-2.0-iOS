//
//  ShelbyVideoReelViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyAirPlayController.h"
#import "VideoControlsViewController.h"
#import "VideoOverlayView.h"

@interface ShelbyVideoReelViewController : ShelbyViewController <VideoControlsDelegate, SPVideoReelDelegate, ShelbyAirPlayControllerDelegate>

@property (nonatomic, strong) VideoControlsViewController *videoControlsVC;
@property (nonatomic, strong) VideoOverlayView *videoOverlayView;

// does not change playback
- (void)setDeduplicatedEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel;

// does affect playback
- (void)playChannel:(DisplayChannel *)channel withDeduplicatedEntries:(NSArray *)channelEntries atIndex:(NSUInteger)idx;

@end
