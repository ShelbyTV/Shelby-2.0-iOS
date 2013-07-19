//
//  WelcomeFlowUFOView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeFlowUFOView : UIView
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

//the position in space, relative to (0,0) of iPhone screen
@property (strong, nonatomic) NSLayoutConstraint *posX;
@property (strong, nonatomic) NSLayoutConstraint *posY;

@property (strong, nonatomic) NSLayoutConstraint *width;
@property (strong, nonatomic) NSLayoutConstraint *height;

@property (assign, nonatomic) CGPoint initialPoint;
@property (assign, nonatomic) CGSize initialSize;
@property (assign, nonatomic) CGPoint initialStackPoint;
@property (assign, nonatomic) CGSize stackSize;

@end
