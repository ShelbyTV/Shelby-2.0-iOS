//
//  WelcomeFlowUFOView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowUFOView.h"

@implementation WelcomeFlowUFOView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)moveToRandomPositionForFrame:(CGRect)frame
{
    _posX.constant = arc4random_uniform(frame.size.width);
    _posY.constant = arc4random_uniform(frame.size.height);
    [self setNeedsUpdateConstraints];
}

- (void)moveToInitialPosition
{
    _posX.constant = _initialPoint.x;
    _posY.constant = _initialPoint.y;
    [self setNeedsUpdateConstraints];
}

- (void)moveToInitialStackPositionPercent:(CGFloat)pct
{
    //position
    _posX.constant = _initialPoint.x + ((_initialStackPoint.x - _initialPoint.x) * pct);
    _posY.constant = _initialPoint.y + ((_initialStackPoint.y - _initialPoint.y) * pct);
    //size
    _width.constant = _initialSize.width + ((_stackSize.width - _initialSize.width) * pct);
    _height.constant = _initialSize.height + ((_stackSize.height - _initialSize.height) * pct);
    [self setNeedsUpdateConstraints];
}

- (void)startReturnHomeLoopWithVelocity:(CGFloat)pointsPerSecond
{
    // set up an animation block based on my currentY, my returnHomeLoopEndY, and my pointsPerSecond velocity
    CGFloat pointsToTravel = _posY.constant - _returnHomeLoopEndY;
    NSTimeInterval travelTimeSeconds = pointsToTravel / pointsPerSecond;

    self.posY.constant = self.returnHomeLoopEndY;
    [self setNeedsUpdateConstraints];

    [UIView animateWithDuration:travelTimeSeconds animations:^{
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            //reset and restart
            self.posY.constant = self.returnHomeLoopStartY;
            [self.superview layoutIfNeeded];
            [self startReturnHomeLoopWithVelocity:pointsPerSecond];
        } else {
            //we've been cancelled
        }
    }];
}

- (void)cancelReturnHomeLoopAtCurrentPosition
{
    // 1) cancel animation by setting view's location to it's actual current in-flight position
    self.posY.constant = [[self.layer presentationLayer] frame].origin.y;
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.0 animations:^{
        [self.superview layoutIfNeeded];
    }];

    // 2) and reset my initialStackPoint to my current position
    self.initialStackPoint = CGPointMake(_posX.constant, _posY.constant);
}

@end
