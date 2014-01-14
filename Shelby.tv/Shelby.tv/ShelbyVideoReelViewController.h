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

extern NSString * const kShelbySingleTapOnVideReelNotification;

@interface ShelbyVideoReelViewController : ShelbyViewController <VideoControlsDelegate, SPVideoReelDelegate>

- (void)loadChannel:(DisplayChannel *)channel withChannelEntries:(NSArray *)channelEntries andAutoPlay:(BOOL)autoPlay;

@property (nonatomic, strong) VideoControlsViewController *videoControlsVC;

@end
