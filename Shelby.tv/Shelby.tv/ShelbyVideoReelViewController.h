//
//  ShelbyVideoReelViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "VideoControlsViewController.h"
#import "VideoOverlayView.h"

extern NSString * const kShelbySingleTapOnVideReelNotification;

@interface ShelbyVideoReelViewController : ShelbyViewController <VideoControlsDelegate, SPVideoReelDelegate>

@property (nonatomic, strong) VideoControlsViewController *videoControlsVC;
@property (nonatomic, strong) VideoOverlayView *videoOverlayView;

- (void)loadChannel:(DisplayChannel *)channel withChannelEntries:(NSArray *)channelEntries andAutoPlay:(BOOL)autoPlay;

@end
