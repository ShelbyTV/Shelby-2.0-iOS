//
//  StreamBrowseCellForegroundView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame+Helper.h"


@protocol StreamBrowseCellForegroundViewDelegate <NSObject>
- (void)streamBrowseCellForegroundViewTitleWasTapped;
@end


@interface StreamBrowseCellForegroundView : UIView
@property (nonatomic, assign) id<StreamBrowseCellForegroundViewDelegate>delegate;

- (void)setInfoForFrame:(Frame *)videoFrame;
@end
