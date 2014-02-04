//
//  NoContentView.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 2/4/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "NoContentView.h"

NSString * const kNoContentViewsNibName = @"NoContentViews";
#define NO_ACTIVITY_VIEW_IDX 0
#define NO_FOLLOWINGS_VIEW_IDX 1
#define NO_NOTIFICATIONS_VIEW_IDX 2

@implementation NoContentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

+ (NSArray *)nib
{
    static NSArray *nibArray;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        nibArray = [[NSBundle mainBundle] loadNibNamed:kNoContentViewsNibName owner:nil options:nil];
    });
    return nibArray;
}

+ (instancetype)noActivityView
{
    return [NoContentView nib][NO_ACTIVITY_VIEW_IDX];
}

+ (CGFloat)noActivityCellHeight
{
    static CGFloat noActivityCellHeight = 200.f;
    return noActivityCellHeight;
}

+ (instancetype)noFollowingsView
{
    return [NoContentView nib][NO_FOLLOWINGS_VIEW_IDX];
}

+ (CGFloat)noFollowingsCellHeight
{
    static CGFloat noFollowingsCellHeight = 300.f;
    return noFollowingsCellHeight;
}

+ (instancetype)noNotificationsView
{
    return [NoContentView nib][NO_NOTIFICATIONS_VIEW_IDX];
}

+ (CGFloat)noNotificationsCellHeight
{
    static CGFloat noNotificationsCellHeight = 300.f;
    return noNotificationsCellHeight;
}

@end
