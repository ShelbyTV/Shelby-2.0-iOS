//
//  ShelbyStreamInfoViewController.h
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "ShelbyVideoReelViewController.h"

@interface ShelbyStreamInfoViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) DisplayChannel *displayChannel;
@property (nonatomic, strong) ShelbyVideoReelViewController *videoReelVC;
@property (nonatomic, assign) BOOL shouldInitializeVideoReel;

@end
