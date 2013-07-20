//
//  WelcomeFlowUFOMothershipViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowUFOMothershipViewController.h"
#import "AHEasing/easing.h"
#import "UIView+EasingFunctions/UIView+EasingFunctions.h"
#import "WelcomeFlowUFOView.h"

#define PAGE_WIDTH 320.0f

@interface WelcomeFlowUFOMothershipViewController () {
    NSArray *_ufos;
    NSArray *_ufosAboveMothership;
    NSUInteger _lastPage;
    BOOL _ufoReturnHomeLoopActive;
}

@property (weak, nonatomic) IBOutlet UIView *mothershipView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipDistanceToBottom;

@end

@implementation WelcomeFlowUFOMothershipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _lastPage = 0;
        _ufoReturnHomeLoopActive = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createUFOs];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self moveUFOsToRandomPositions];
}

- (void)viewDidAppear:(BOOL)animated
{
    [UIView animateWithDuration:0.5 animations:^{
        [self moveUFOsToInitialPositions];
    }];
}

- (void)controllingContentOffsetDidChange:(CGPoint)offset
{
    if (offset.x < PAGE_WIDTH /* TODO: && !_ufosLoopingIntoMothership ??? */) {
        [self moveUFOsToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];
        [self moveMothershipToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];
    }
    
}

- (void)pageDidChange:(NSUInteger)page
{

    switch (page) {
        case 0:
            _lastPage = 0;
            break;
        case 1:
            if (_lastPage == 0) {
                [self startUFOReturnHomeLoops];
            }
            _lastPage = 1;
            break;

        default:
            break;
    }
}

#pragma mark - Private Helpers

- (void)startUFOReturnHomeLoops
{
    //TODO: let's just try making them loop, continuously, for now
    _ufoReturnHomeLoopActive = YES;
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo startReturnHomeLoopWithVelocity:4];
    }



    // Could just have the UFOs loop continuously and have the mothership cycle videos
    // and not necessarily have them perfectly coordinated
    // coordinate just enough to fake it

}

- (void)moveUFOsToInitialStackPositionPercent:(CGFloat)pct
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo moveToInitialStackPositionPercent:pct];
    }
    //undo special Z position for some
    for (WelcomeFlowUFOView *ufo in _ufosAboveMothership) {
        [self.view insertSubview:ufo belowSubview:self.mothershipView];
    }
    
    [self.view layoutIfNeeded];
}

- (void)moveMothershipToInitialStackPositionPercent:(CGFloat)pct
{
    self.mothershipDistanceToBottom.constant = 270 - (80*pct);
    [self.view layoutIfNeeded];
}

- (void)moveUFOsToInitialPositions
{    
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo moveToInitialPosition];
    }
    //special Z position for some
    for (WelcomeFlowUFOView *ufo in _ufosAboveMothership) {
        [self.view insertSubview:ufo aboveSubview:self.mothershipView];
    }

    [self.view layoutIfNeeded];
}

- (void)moveUFOsToRandomPositions
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo moveToRandomPositionForFrame:self.view.frame];
    }
}

- (void)createUFOs
{
    //size and position of all UFOs when in stack
    CGSize kShelbyUFOStackSize = CGSizeMake(50, 50);
    CGFloat stackX = (PAGE_WIDTH / 2.0f) - (50.0f/2.0f);
    CGFloat stackY = self.mothershipView.frame.origin.y + self.mothershipView.frame.size.height + 10;
    //distance between each UFO in the stack
    CGFloat StackYDelta = 60;

    //the point within the mothership where UFO moves to bottom of stack to restart its journey home
    CGFloat returnHomeLoopEndY = stackY - (2*StackYDelta);
    //the bottom of the stack where UFO should restarts its journey home
    //this has to account for number of UFOs minus distance they travel into mothership before restarting
    CGFloat returnHomeLoopStartY = stackY + (5*StackYDelta);
    //NB: UFO algorithm makes sure it moves at a constant velocity, keeping them all evenly spaced

    _ufos = @[[self createUFOWithTitle:@"FB0"
                                  size:CGSizeMake(80, 80)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(250, 30)
                     initialStackPoint:CGPointMake(stackX, stackY + (0*StackYDelta))],
              [self createUFOWithTitle:@"YT1"
                                  size:CGSizeMake(60, 60)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(250, 200)
                     initialStackPoint:CGPointMake(stackX, stackY + (1*StackYDelta))],
              [self createUFOWithTitle:@"YT2"
                                  size:CGSizeMake(40, 40)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(75, 265)
                     initialStackPoint:CGPointMake(stackX, stackY + (2*StackYDelta))],
              [self createUFOWithTitle:@"YT3"
                                  size:CGSizeMake(60, 60)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(10, 200)
                     initialStackPoint:CGPointMake(stackX, stackY + (3*StackYDelta))],
              [self createUFOWithTitle:@"YT4"
                                  size:CGSizeMake(40, 40)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(-10, 120)
                     initialStackPoint:CGPointMake(stackX, stackY + (4*StackYDelta))],
              [self createUFOWithTitle:@"YT5"
                                  size:CGSizeMake(50, 50)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(-10, 50)
                     initialStackPoint:CGPointMake(stackX, stackY + (5*StackYDelta))],
              [self createUFOWithTitle:@"YT6"
                                  size:CGSizeMake(60, 60)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(50, 0)
                     initialStackPoint:CGPointMake(stackX, stackY + (6*StackYDelta))],
              [self createUFOWithTitle:@"TWT"
                                  size:CGSizeMake(40, 40)
                             stackSize:kShelbyUFOStackSize
                          initialPoint:CGPointMake(200, 0)
                     initialStackPoint:CGPointMake(stackX, stackY + (7*StackYDelta))]];
    
    for (WelcomeFlowUFOView *ufo in _ufos) {
        ufo.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view insertSubview:ufo belowSubview:self.mothershipView];

        ufo.posX = [NSLayoutConstraint constraintWithItem:ufo
                                                attribute:NSLayoutAttributeLeft
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view
                                                attribute:NSLayoutAttributeLeft
                                               multiplier:1
                                                 constant:0];
        ufo.posY = [NSLayoutConstraint constraintWithItem:ufo
                                                attribute:NSLayoutAttributeTop
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.view
                                                attribute:NSLayoutAttributeTop
                                               multiplier:1
                                                 constant:0];
        [self.view addConstraints:@[ufo.posX, ufo.posY]];

        [ufo setEasingFunction:BackEaseInOut forKeyPath:@"frame"];

        ufo.returnHomeLoopEndY = returnHomeLoopEndY;
        ufo.returnHomeLoopStartY = returnHomeLoopStartY;

        //XXX remove this testing crap
        ufo.layer.borderColor = [UIColor redColor].CGColor;
        ufo.layer.borderWidth = 1.0;
    }
}

- (WelcomeFlowUFOView *)createUFOWithTitle:(NSString *)name
                                      size:(CGSize)size
                                 stackSize:(CGSize)stackSize
                              initialPoint:(CGPoint)initialPoint
                         initialStackPoint:(CGPoint)initialStackPoint
{
    WelcomeFlowUFOView *ufo = [[NSBundle mainBundle] loadNibNamed:@"WelcomeFlowUFO" owner:self options:nil][0];
    ufo.nameLabel.text = name;
    ufo.initialPoint = initialPoint;
    ufo.initialStackPoint = initialStackPoint;
    ufo.stackSize = stackSize;
    ufo.initialSize = size;
    ufo.width = [NSLayoutConstraint constraintWithItem:ufo
                                             attribute:NSLayoutAttributeWidth
                                             relatedBy:nil
                                                toItem:nil
                                             attribute:nil
                                            multiplier:0
                                              constant:size.width];
    ufo.height = [NSLayoutConstraint constraintWithItem:ufo
                                              attribute:NSLayoutAttributeHeight
                                              relatedBy:nil
                                                 toItem:nil
                                              attribute:nil
                                             multiplier:0
                                               constant:size.height];
    [ufo addConstraints:@[ufo.width, ufo.height]];
    return ufo;
}

@end
