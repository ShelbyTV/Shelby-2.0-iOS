//
//  WelcomeScrollHolderView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STVParallaxView.h"

@interface WelcomeScrollHolderView : UIView<UIScrollViewDelegate, STVParallaxViewDelegate>

//NB: we are only passing a subset of delegate callbacks
@property (weak, nonatomic) id<UIScrollViewDelegate>scrollViewDelegate;

@end
