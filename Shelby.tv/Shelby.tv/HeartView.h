//
//  HeartView.h
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HeartView : UIView
- (void)addPointsToView;
- (void)setProgress:(CGFloat)progress; // should be between 0-1
- (void)fillShape;
@end
