//
//  ShelbyTopBottomAnimationViews.m
//  Shelby.tv
//
//  Created by Keren on 5/6/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHideBrowseAnimationViews.h"

@interface ShelbyHideBrowseAnimationViews()
@property (nonatomic, strong) UIImageView *topView;
@property (nonatomic, strong) UIImageView *centerView;
@property (nonatomic, strong) UIImageView *bottomView;

@property (nonatomic, assign) CGRect finalTopFrame;
@property (nonatomic, assign) CGRect finalCenterFrame;
@property (nonatomic, assign) CGRect finalBottomFrame;

@end

@implementation ShelbyHideBrowseAnimationViews


+ (ShelbyHideBrowseAnimationViews *)createWithTop:(UIImageView *)top
                                    finalTopFrame:(CGRect)finalTopFrame
                                           center:(UIImageView *)center
                                 finalCenterFrame:(CGRect)finalCenterFrame
                                           bottom:(UIImageView *)bottom
                              andFinalBottomFrame:(CGRect)finalBottomFrame
{
    ShelbyHideBrowseAnimationViews *views = [[ShelbyHideBrowseAnimationViews alloc] init];
    views.topView = top;
    views.finalTopFrame = finalTopFrame;
    views.bottomView = bottom;
    views.finalBottomFrame = finalBottomFrame;
    views.centerView = center;
    views.finalCenterFrame = finalCenterFrame;

    return views;
}
@end
