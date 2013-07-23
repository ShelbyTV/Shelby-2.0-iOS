//
//  WelcomeFlowUFOView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowUFOView.h"

@interface WelcomeFlowUFOView() {
    //random initial point
    CGPoint _randomEntrancePoint;
    //offscreen for the signup/login page
    CGPoint _randomExitPoint;

    //sizing
    NSLayoutConstraint *_width;
    NSLayoutConstraint *_height;

    //position in space, relative to (0,0) of iPhone screen
    NSLayoutConstraint *_posX;
    NSLayoutConstraint *_posY;
}

@property (weak, nonatomic) IBOutlet UIImageView *image;

@end

@implementation WelcomeFlowUFOView

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)didMoveToSuperview
{
    [self setBackgroundImage];

    //setup X/Y constraints
    _posX = [NSLayoutConstraint constraintWithItem:self
                                         attribute:NSLayoutAttributeLeft
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.superview
                                         attribute:NSLayoutAttributeLeft
                                        multiplier:1
                                          constant:0];
    _posY = [NSLayoutConstraint constraintWithItem:self
                                         attribute:NSLayoutAttributeTop
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.superview
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1
                                          constant:0];
    [self.superview addConstraints:@[_posX, _posY]];

    //set some nice randomish entrance/exit points
    CGRect frame = self.superview.frame;
    _randomEntrancePoint = CGPointMake(arc4random_uniform(frame.size.width), arc4random_uniform(frame.size.height));
    CGFloat exitX = (arc4random_uniform(3) > 1) ? (-100) : (600);
    CGFloat exitY = (arc4random_uniform(3) > 1) ? (-100) : (-500);
    _randomExitPoint = CGPointMake(exitX, exitY);
}

- (void)setInitialSize:(CGSize)size
{
    _initialSize = size;

    //constraints so we can control our size when moving to/from the stack
    _width = [NSLayoutConstraint constraintWithItem:self
                                          attribute:NSLayoutAttributeWidth
                                          relatedBy:nil
                                             toItem:nil
                                          attribute:nil
                                         multiplier:0
                                           constant:size.width];
    _height = [NSLayoutConstraint constraintWithItem:self
                                           attribute:NSLayoutAttributeHeight
                                           relatedBy:nil
                                              toItem:nil
                                           attribute:nil
                                          multiplier:0
                                            constant:size.height];
    [self addConstraints:@[_width, _height]];
}

- (void)setBackgroundImage
{
    if (self.imageName) {
        self.image.image = [UIImage imageNamed:self.imageName];
    }
}

- (void)moveToEntrancePosition
{
    _posX.constant = _randomEntrancePoint.x;
    _posY.constant = _randomEntrancePoint.y;
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

    _posY.constant = self.returnHomeLoopEndY;
    [self setNeedsUpdateConstraints];

    [UIView animateWithDuration:travelTimeSeconds animations:^{
        [self.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            //reset and restart
            _posY.constant = self.returnHomeLoopStartY;
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
    _posY.constant = [[self.layer presentationLayer] frame].origin.y;
    [self setNeedsUpdateConstraints];
    [UIView animateWithDuration:0.0 animations:^{
        [self.superview layoutIfNeeded];
    }];

    // 2) and reset my initialStackPoint to my current position
    self.initialStackPoint = CGPointMake(self.initialStackPoint.x, _posY.constant);
}

- (void)moveToExitPositionPercent:(CGFloat)pct
{
    _posX.constant = _initialStackPoint.x + ((_randomExitPoint.x - _initialStackPoint.x) * pct);
    _posY.constant = _initialStackPoint.y + ((_randomExitPoint.y - _initialStackPoint.y) * pct);
    [self setNeedsUpdateConstraints];
}

@end
