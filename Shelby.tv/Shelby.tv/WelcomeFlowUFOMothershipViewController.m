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
}

@property (weak, nonatomic) IBOutlet UIView *mothershipView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipDistanceToBottom;

@end

@implementation WelcomeFlowUFOMothershipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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
    if (offset.x < PAGE_WIDTH) {
        [self moveUFOsToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];
        [self moveMothershipToInitialStackPositionPercent:(offset.x / PAGE_WIDTH)];
    }
    
}

- (void)pageDidChange:(NSUInteger)page
{
    switch (page) {
        case 0:
            [self moveUFOsToInitialPositions];
            break;
        case 1:
            [self moveUFOsToInitialStackPositionPercent:1.0f];
            //TODO: put UFOs behind mothership
            //TODO: animate move mothership down
            //TODO: start UFOs continuous animation
            break;

        default:
            break;
    }
}

#pragma mark - Private Helpers

- (void)moveUFOsToInitialStackPositionPercent:(CGFloat)pct
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        //position
        ufo.posX.constant = ufo.initialPoint.x + ((ufo.initialStackPoint.x - ufo.initialPoint.x) * pct);
        ufo.posY.constant = ufo.initialPoint.y + ((ufo.initialStackPoint.y - ufo.initialPoint.y) * pct);
        //size
        ufo.width.constant = ufo.initialSize.width + ((ufo.stackSize.width - ufo.initialSize.width) * pct);
        ufo.height.constant = ufo.initialSize.height + ((ufo.stackSize.height - ufo.initialSize.height) * pct);
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
        ufo.posX.constant = ufo.initialPoint.x;
        ufo.posY.constant = ufo.initialPoint.y;
    }
    [self.view layoutIfNeeded];
}

- (void)moveUFOsToRandomPositions
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        ufo.posX.constant = arc4random_uniform(self.view.frame.size.width);
        ufo.posY.constant = arc4random_uniform(self.view.frame.size.height);
    }
}

- (void)createUFOs
{
    CGSize kShelbyUFOStackSize = CGSizeMake(50, 50);
    CGFloat stackX = (PAGE_WIDTH / 2.0f) - (50.0f/2.0f);
    CGFloat stackY = self.mothershipView.frame.origin.y + self.mothershipView.frame.size.height + 10;
    CGFloat StackYDelta = 60;

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

        //TODO: better easing function
        [ufo setEasingFunction:BackEaseInOut forKeyPath:@"frame"];

        ufo.layer.borderColor = [UIColor redColor].CGColor;
        ufo.layer.borderWidth = 1.0;
    }
    //special Z position
    [self.view insertSubview:_ufos[3] aboveSubview:self.mothershipView];
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
