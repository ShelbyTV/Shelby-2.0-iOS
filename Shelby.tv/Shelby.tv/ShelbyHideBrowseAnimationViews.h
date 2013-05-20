//
//  ShelbyTopBottomAnimationViews.h
//  Shelby.tv
//
//  Created by Keren on 5/6/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShelbyHideBrowseAnimationViews : NSObject

@property (readonly, nonatomic, strong) UIImageView *topView;
@property (readonly, nonatomic, strong) UIImageView *centerView;
@property (readonly, nonatomic, strong) UIImageView *bottomView;

@property (readonly, nonatomic, assign) CGRect finalTopFrame;
@property (readonly, nonatomic, assign) CGRect finalCenterFrame;
@property (readonly, nonatomic, assign) CGRect finalBottomFrame;


+ (ShelbyHideBrowseAnimationViews *)createWithTop:(UIImageView *)top
                                    finalTopFrame:(CGRect)finalTopFrame
                                           center:(UIImageView *)center
                                 finalCenterFrame:(CGRect)finalCenterFrame
                                           bottom:(UIImageView *)bottom
                              andFinalBottomFrame:(CGRect)finalBottomFrame;
@end
