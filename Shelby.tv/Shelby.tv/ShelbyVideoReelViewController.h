//
//  ShelbyVideoReelViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"

extern NSString * const kShelbySingleTapOnVideReeloNotification;

@interface ShelbyVideoReelViewController : UIViewController

- (void)loadChannel:(DisplayChannel *)channel withChannelEntries:(NSArray *)channelEntries andAutoPlay:(BOOL)autoPlay;
@end
