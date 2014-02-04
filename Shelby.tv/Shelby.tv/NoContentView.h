//
//  NoContentView.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 2/4/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NoContentView : UITableViewCell

+ (instancetype)noActivityView;
+ (CGFloat)noActivityCellHeight;

+ (instancetype)noFollowingsView;
+ (CGFloat)noFollowingsCellHeight; //unused

+ (instancetype)noNotificationsView;
+ (CGFloat)noNotificationsCellHeight; //unused

@end
