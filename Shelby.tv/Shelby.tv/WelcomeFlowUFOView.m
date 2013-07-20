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
}

- (void)moveToInitialPosition
{
    _posX.constant = _initialPoint.x;
    _posY.constant = _initialPoint.y;
}

- (void)moveToInitialStackPositionPercent:(CGFloat)pct
{
    //position
    _posX.constant = _initialPoint.x + ((_initialStackPoint.x - _initialPoint.x) * pct);
    _posY.constant = _initialPoint.y + ((_initialStackPoint.y - _initialPoint.y) * pct);
    //size
    _width.constant = _initialSize.width + ((_stackSize.width - _initialSize.width) * pct);
    _height.constant = _initialSize.height + ((_stackSize.height - _initialSize.height) * pct);
}

- (void)startReturnHomeLoopWithVelocity:(CGFloat)pointsPerSecond
{
    //TODO
}

@end
