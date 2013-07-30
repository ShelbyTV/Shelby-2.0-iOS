//
//  WelcomeFlowUFOMothershipViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/19/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowUFOMothershipViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AHEasing/easing.h"
#import "UIView+EasingFunctions/UIView+EasingFunctions.h"
#import "WelcomeFlowUFOView.h"

#define PAGE_WIDTH 320.0f
#define MOTHERSHIP_INITIAL_STACK_Y 140.0f
#define MOTHERSHIP_INITIAL_POSITION_STACK_DELTA 90.0f

@interface WelcomeFlowUFOMothershipViewController () {
    NSArray *_ufos;
    NSArray *_ufosAboveMothership;
    NSMutableArray *_videoPlayers;
    NSMutableArray *_videoPlayerViews;
    NSUInteger _curVideoPlayerIdx;
    NSTimer *_mothershipVideoDisplayTimer;
    BOOL _ufoReturnHomeLoopActive;
    NSUInteger _currentPage;
}

@property (weak, nonatomic) IBOutlet UIView *mothershipView;
@property (weak, nonatomic) IBOutlet UIImageView *mothershipVideoDisplay;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipY;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *mothershipOverlayX;
@property (weak, nonatomic) IBOutlet UIView *mothershipOverlay;

@end

@implementation WelcomeFlowUFOMothershipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _ufoReturnHomeLoopActive = NO;
        _currentPage = 0;
        _curVideoPlayerIdx = 0;
        _videoPlayers = [@[] mutableCopy];
        _videoPlayerViews = [@[] mutableCopy];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mothershipView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"welcome-logo"]];
    self.mothershipView.layer.cornerRadius = 5.0;
    self.mothershipView.layer.masksToBounds = YES;
    [self createUFOs];
    [self createVideoPlayers];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_currentPage == 0) {
        [self moveUFOsToEntrancePositions];
        [self moveMothershipToInitialStackPositionPercent:0];
        [self moveMothershipOverlayToCoverPercent:0];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    if (_currentPage == 0) {
        [self moveUFOsToInitialPositions];
    }
}

- (void)controllingContentOffsetDidChange:(CGPoint)offset
{

    if (offset.x < PAGE_WIDTH) {
        /* 1 -> 2
         * moving UFOs between initial position and initial stack position based on offset
         * move mothership into position to receive UFOs
         */
        if (_ufoReturnHomeLoopActive) {
            [self cancelUFOReturnHomeLoops];
            [self cancelMothershipVideoDisplayLoops];
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
            [self cancelUFOReturnHomeLoops];
            [self cancelMothershipVideoDisplayLoops];
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
            [self moveMothershipOverlayToCoverPercent:0];
            _currentPage = 0;
            break;
        case 1:
            _currentPage = 1;
            [self moveMothershipOverlayToCoverPercent:0];
            if (!_ufoReturnHomeLoopActive) {
                [self moveUFOsToInitialStackPositionPercent:1.0];
                [self moveMothershipToInitialStackPositionPercent:1.0];
                [self startUFOReturnHomeLoops];
                [self mothershipChangeVideoOnDisplay];
            }
            break;
        case 2:
            _currentPage = 2;
            [self moveMothershipOverlayToCoverPercent:1.0];
            if (!_ufoReturnHomeLoopActive) {
                [self moveUFOsToInitialStackPositionPercent:1.0];
                [self moveMothershipToInitialStackPositionPercent:1.0];
                [self startUFOReturnHomeLoops];
                [self mothershipChangeVideoOnDisplay];
            }
            break;
        case 3:
            _currentPage = 3;
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
    self.mothershipY.constant = MOTHERSHIP_INITIAL_STACK_Y - (self.view.frame.size.height * pct*pct);
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

}

- (void)cancelUFOReturnHomeLoops
{
    for (WelcomeFlowUFOView *ufo in _ufos) {
        [ufo cancelReturnHomeLoopAtCurrentPosition];
    }
}

- (void)mothershipChangeVideoOnDisplay
{
    if (_ufoReturnHomeLoopActive) {
        AVPlayer *curPlayer = _videoPlayers[_curVideoPlayerIdx];
        UIView *curPlayerView = _videoPlayerViews[_curVideoPlayerIdx];
        AVPlayer *nextPlayer = [self nextVideoPlayer]; //updates _curVideoPlayerIdx
        UIView *nextPlayerView = _videoPlayerViews[_curVideoPlayerIdx];

        nextPlayerView.frame = CGRectMake(0, nextPlayerView.frame.size.height, nextPlayerView.frame.size.width, nextPlayerView.frame.size.height);
        //animate scroll up halfway
        [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            curPlayerView.frame = CGRectMake(0, -curPlayerView.frame.size.height/2, curPlayerView.frame.size.width, curPlayerView.frame.size.height);
            nextPlayerView.frame = CGRectMake(0, curPlayerView.frame.size.height/2, nextPlayerView.frame.size.width, nextPlayerView.frame.size.height);
        } completion:^(BOOL finished) {

            //swap playback when they're 50% way up
            [curPlayer pause];
            [nextPlayer play];

            //animate scroll next half of the way
            [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
                curPlayerView.frame = CGRectMake(0, -curPlayerView.frame.size.height, curPlayerView.frame.size.width, curPlayerView.frame.size.height);
                nextPlayerView.frame = CGRectMake(0, 0, nextPlayerView.frame.size.width, nextPlayerView.frame.size.height);
            } completion:^(BOOL finished) {
                [curPlayer seekToTime:CMTimeMakeWithSeconds(0, NSEC_PER_SEC)];
            }];
        }];

        _mothershipVideoDisplayTimer = [NSTimer scheduledTimerWithTimeInterval:3.5
                                                                        target:self
                                                                      selector:@selector(mothershipChangeVideoOnDisplay)
                                                                      userInfo:nil
                                                                       repeats:NO];
    }
}

- (void)cancelMothershipVideoDisplayLoops
{
    [_mothershipVideoDisplayTimer invalidate];
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
    if (pct >= 0) {
        self.mothershipVideoDisplay.alpha = pct*pct;
    }
    self.mothershipY.constant = MOTHERSHIP_INITIAL_STACK_Y - (MOTHERSHIP_INITIAL_POSITION_STACK_DELTA*(1.0f-pct));
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
    CGFloat stackY = MOTHERSHIP_INITIAL_STACK_Y + self.mothershipView.frame.size.height + 10;
    //distance between each UFO in the stack
    CGFloat StackYDelta = 60;

    //the point within the mothership where UFO moves to bottom of stack to restart its journey home
    CGFloat returnHomeLoopEndY = stackY - (2*StackYDelta);
    //the bottom of the stack where UFO should restarts its journey home
    //this has to account for number of UFOs minus distance they travel into mothership before restarting
    CGFloat returnHomeLoopStartY = stackY + (5*StackYDelta);
    //NB: UFO algorithm makes sure it moves at a constant velocity, keeping them all evenly spaced

    _ufos = @[[self createUFOWithImageNamed:@"welcome-buzzfeed"
                                       size:CGSizeMake(80, 80)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(250, 30)
                          initialStackPoint:CGPointMake(stackX, stackY + (0*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-facebook"
                                       size:CGSizeMake(60, 60)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(250, 200)
                          initialStackPoint:CGPointMake(stackX, stackY + (1*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-hungry"
                                       size:CGSizeMake(40, 40)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(75, 265)
                          initialStackPoint:CGPointMake(stackX, stackY + (2*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-patagonia"
                                       size:CGSizeMake(60, 60)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(10, 200)
                          initialStackPoint:CGPointMake(stackX, stackY + (3*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-rsrv"
                                       size:CGSizeMake(40, 40)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(-10, 120)
                          initialStackPoint:CGPointMake(stackX, stackY + (4*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-squid"
                                       size:CGSizeMake(50, 50)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(-10, 50)
                          initialStackPoint:CGPointMake(stackX, stackY + (5*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-ted"
                                       size:CGSizeMake(60, 60)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(50, -10)
                          initialStackPoint:CGPointMake(stackX, stackY + (6*StackYDelta))],
              [self createUFOWithImageNamed:@"welcome-twitter"
                                       size:CGSizeMake(40, 40)
                                  stackSize:kShelbyUFOStackSize
                               initialPoint:CGPointMake(200, 3)
                          initialStackPoint:CGPointMake(stackX, stackY + (7*StackYDelta))]];
    
    for (WelcomeFlowUFOView *ufo in _ufos) {
        ufo.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view insertSubview:ufo belowSubview:self.mothershipView];

        ufo.returnHomeLoopEndY = returnHomeLoopEndY;
        ufo.returnHomeLoopStartY = returnHomeLoopStartY;
    }

    _ufosAboveMothership = @[_ufos[3], _ufos[5], _ufos[7]];
}

- (WelcomeFlowUFOView *)createUFOWithImageNamed:(NSString *)imageName
                                           size:(CGSize)size
                                      stackSize:(CGSize)stackSize
                                   initialPoint:(CGPoint)initialPoint
                              initialStackPoint:(CGPoint)initialStackPoint
{
    WelcomeFlowUFOView *ufo = [[NSBundle mainBundle] loadNibNamed:@"WelcomeFlowUFO" owner:self options:nil][0];

    ufo.imageName = imageName;

    //where does ufo start (floating about mothership)
    ufo.initialPoint = initialPoint;
    ufo.initialSize = size;

    //line up below the mothership the first time
    ufo.initialStackPoint = initialStackPoint;
    ufo.stackSize = stackSize;
    
    return ufo;
}

- (void)createVideoPlayers
{
    [self createPlayerAndAddToViewWithVideo:@"buzzfeed"];
    [self createPlayerAndAddToViewWithVideo:@"facebook"];
    //TODO: add hungry here
    [self createPlayerAndAddToViewWithVideo:@"patagonia"];
    //TODO: add (in order) rsrv, laughing squid, TED
    [self createPlayerAndAddToViewWithVideo:@"twitter"];
    [self createPlayerAndAddToViewWithVideo:@"vice"];

    //put the first one in position so initial animations are nice
    UIView *initialPlayerView = _videoPlayerViews[_curVideoPlayerIdx];
    initialPlayerView.frame = CGRectMake(0, 0, initialPlayerView.frame.size.width, initialPlayerView.frame.size.height);
}

- (void)createPlayerAndAddToViewWithVideo:(NSString *)videoFileName
{
    NSURL *vidURL = [[NSBundle mainBundle] URLForResource:videoFileName withExtension:@"m4v"];
    
    AVURLAsset *playerAsset = [AVURLAsset URLAssetWithURL:vidURL options:nil];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithAsset:playerAsset];
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];

    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    playerLayer.anchorPoint = CGPointMake(0, 0);
    playerLayer.bounds = CGRectMake(0, 0, self.mothershipView.frame.size.width, self.mothershipView.frame.size.height);
    //but animating layers is a pain, so i'm wrapping them in UIViews
    UIView *playerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.mothershipView.frame.size.height, self.mothershipView.frame.size.width, self.mothershipView.frame.size.height)];
    [playerView.layer addSublayer:playerLayer];

    [self.mothershipVideoDisplay addSubview:playerView];

    [_videoPlayers addObject:player];
    [_videoPlayerViews addObject:playerView];
}

- (AVPlayer *)nextVideoPlayer
{
    if (++_curVideoPlayerIdx == [_videoPlayers count]) {
        _curVideoPlayerIdx = 0;
    }
    return _videoPlayers[_curVideoPlayerIdx];
}

@end
