//
//  ShelbyHomeViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowseViewController.h"
#import "User.h"

@interface ShelbyHomeViewController : UIViewController

@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) User *currentUser;

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel;
- (void)setBrowseDelegete:(id<ShelbyBrowseProtocol>)delegete;
- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index;
@end
