//
//  BrowseChannelsHeaderView.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BrowseChannelsHeaderView : UIView

- (void)resetFollowCount;
- (void)increaseFollowCount;
- (void)decreaseFollowCount;
- (BOOL)hitTargetFollowCount;

@end
