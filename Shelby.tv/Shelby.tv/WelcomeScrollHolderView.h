//
//  WelcomeScrollHolderView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeScrollHolderView : UIView<UIScrollViewDelegate>

//NB: we are only passing a subset of delegate callbacks
@property (weak, nonatomic) id<UIScrollViewDelegate>scrollViewDelegate;

@end
