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
#define MOTHERSHIP_INITIAL_STACK_POSITION 190.0f

@interface WelcomeFlowUFOMothershipViewController () {
    NSArray *_ufos;
    NSArray *_ufosAboveMothership;
    BOOL _ufoReturnHomeLoopActive;
}

@property (weak, nonatomic) IBOutlet UIView *mothershipView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipDistanceToBottom;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipOverlayX;

@end

@implementation WelcomeFlowUFOMothershipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
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
    [self moveUFOsToEntrancePositions];
    [self moveMothershipOverlayToCoverPercent:0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self moveUFOsToInitialPositions];
}

- (void)controllingContentOffsetDidChange:(CGPoint)offset
{

    if (offset.x < PAGE_WIDTH) {
        /* 1 -> 2
         * moving UFOs between initial position and initial stack position based on offset
         * move mothership into position to receive UFOs
         */
        if (_ufoReturnHomeLoopActive) {
            for (WelcomeFlowUFOView *ufo in _ufos) {
                [ufo cancelReturnHomeLoopAtCurrentPosition];
            }
            _ufoReturnHomeLoopActive = NO;
        }

        [self moveUFOsToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];
        [self moveMothershipToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];

    } else if (offset.x > PAGE_WIDTH && offset.x < 2 * PAGE_WIDTH) {
        /* 2 -> 3
         * move the overlay to cover the motherhsip
         */
        [self moveMothershipOverlayToCoverPercent:(offset.x - PAGE_WIDTH) / PAGE_WIDTH];

    } else if (offset.x > 2 * PAGE_WIDTH) {
        /* 3 -> 4
         * moving UFOs between stack position and a final, offscreen position
         * have mothership fly away
         */
        if (_ufoReturnHomeLoopActive) {
            for (WelcomeFlowUFOView *ufo in _ufos) {
                [ufo cancelReturnHomeLoopAtCurrentPosition];
            }
            _ufoReturnHomeLoopActive = NO;
        }

        CGFloat pct = (offset.x - 2*PAGE_WIDTH) / PAGE_WIDTH;
        [self moveUFOsToExitPositionPercent:pct];
        [self moveMothershipToExitPositionPercent:pct];

    }

}

- (void)pageDidChange:(NSUInteger)page
{
    switch (page) {
        case 0:
            //noop
            break;
        case 1:
            [self moveMothershipOverlayToCoverPercent:0];
            if (!_ufoReturnHomeLoopActive) {
                [self moveUFOsToInitialStackPositionPercent:1.0];
                [self moveMothershipToInitialStackPositionPercent:1.0];
                [self startUFOReturnHomeLoops];
            }
            break;
        case 2:
            [self moveMothershipOverlayToCoverPercent:1.0];
            if (!_ufoReturnHomeLoopActive) {
                [self moveUFOsToInitialStackPositionPercent:1.0];
                [self moveMothershipToInitialStackPositionPercent:1.0];
                [self startUFOReturnHomeLoops];
            }
            break;
        case 3:
            //noop
            break;

        default:
            STVAssert(NO, @"should handle all pages");
            break;
    }
}

#pragma mark - Private Helpers

- (void)moveMothershipOverlayToCoverPercent:(CGFloat)pct
{
    self.mothershipOverlayX.constant = self.mothershipView.frame.size.width * (1-pct);
    [self.mothershipView setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)moveUFOsToExitPositionPercent:(CGFloat)pct
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo moveToExitPositionPercent:pct];
    }
    
    [self.view layoutIfNeeded];
}

- (void)moveMothershipToExitPositionPercent:(CGFloat)pct
{
    self.mothershipDistanceToBottom.constant = MOTHERSHIP_INITIAL_STACK_POSITION + (self.view.frame.size.height * pct)*pct;
    [self.mothershipView setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)startUFOReturnHomeLoops
{
    //undo special Z position for some
    for (WelcomeFlowUFOView *ufo in _ufosAboveMothership) {
        [self.view insertSubview:ufo belowSubview:self.mothershipView];
    }
    
    //make them all start their loops
    _ufoReturnHomeLoopActive = YES;
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo startReturnHomeLoopWithVelocity:20];
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
    [self.view layoutIfNeeded];
}

- (void)moveMothershipToInitialStackPositionPercent:(CGFloat)pct
{
    self.mothershipDistanceToBottom.constant = MOTHERSHIP_INITIAL_STACK_POSITION + (80.0f*(1.0f-pct));
    [self.mothershipView setNeedsUpdateConstraints];
    [self.view layoutIfNeeded];
}

- (void)moveUFOsToInitialPositions
{
    //location & initial easing
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo setEasingFunction:BackEaseInOut forKeyPath:@"frame"];
        [ufo moveToInitialPosition];
    }
    //special Z position for some
    for (WelcomeFlowUFOView *ufo in _ufosAboveMothership) {
        [self.view insertSubview:ufo aboveSubview:self.mothershipView];
    }

    //animate these changes
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        //reset easing
        for (WelcomeFlowUFOView *ufo in _ufos) {
            [ufo setEasingFunction:LinearInterpolation forKeyPath:@"frame"];
        }
    }];
}

- (void)moveUFOsToEntrancePositions
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo moveToEntrancePosition];
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
    CGFloat returnHomeLoopEndY = stackY - (3*StackYDelta);
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

        ufo.returnHomeLoopEndY = returnHomeLoopEndY;
        ufo.returnHomeLoopStartY = returnHomeLoopStartY;

        //XXX for testing
        ufo.layer.borderColor = [UIColor redColor].CGColor;
        ufo.layer.borderWidth = 1.0;
    }

    _ufosAboveMothership = @[_ufos[3], _ufos[5], _ufos[7]];
}

- (WelcomeFlowUFOView *)createUFOWithTitle:(NSString *)name
                                      size:(CGSize)size
                                 stackSize:(CGSize)stackSize
                              initialPoint:(CGPoint)initialPoint
                         initialStackPoint:(CGPoint)initialStackPoint
{
    WelcomeFlowUFOView *ufo = [[NSBundle mainBundle] loadNibNamed:@"WelcomeFlowUFO" owner:self options:nil][0];

    //XXX for testing
    ufo.nameLabel.text = name;

    //where does ufo start (floating about mothership)
    ufo.initialPoint = initialPoint;
    ufo.initialSize = size;

    //line up below the mothership the first time
    ufo.initialStackPoint = initialStackPoint;
    ufo.stackSize = stackSize;
    
    return ufo;
}

@end
