//
//  WelcomeFlowUFOView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WelcomeFlowUFOView : UIView

//XXX for testing
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;

//initialPoint/Size is page 1 when they're about the mothership
@property (assign, nonatomic) CGPoint initialPoint;
@property (assign, nonatomic) CGSize initialSize;

//stackPoint/Size is where they fly to when moving from p1 to p2
@property (assign, nonatomic) CGPoint initialStackPoint;
@property (assign, nonatomic) CGSize stackSize;

//returnHomeLoopStart/End points allow UFO to travel up the stack,
//looping to bottom of stack after entering the mothershhip
@property (assign, nonatomic) CGFloat returnHomeLoopEndY;
@property (assign, nonatomic) CGFloat returnHomeLoopStartY;

//move to a random pre-initial position (only used before viewDidLoad)
- (void)moveToEntrancePosition;

//move to initial position (only used on viewDidLoad)
- (void)moveToInitialPosition;

//moves from initialPoint/Size to stackInitialPoint/Size
- (void)moveToInitialStackPositionPercent:(CGFloat)pct;

//start looping into mothership and then back down to bottom of stack
- (void)startReturnHomeLoopWithVelocity:(CGFloat)pointsPerSecond;
- (void)cancelReturnHomeLoopAtCurrentPosition;

//move to a random, out-of-frame position
- (void)moveToExitPositionPercent:(CGFloat)pct;

@end