//
//  ShelbyEntranceViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/22/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyEntranceViewController.h"
#import "ShelbyDataMediator.h"

@interface ShelbyEntranceViewController ()
@property (weak, nonatomic) IBOutlet UIView *logo;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *logoVerticalSpaceToTop;
@property (weak, nonatomic) IBOutlet UIButton *getStartedButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *getStartedVerticalSpaceToBottom;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *getStartedSpinner;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *loginVerticalSpaceToBottom;

//blurry background
@property (nonatomic, assign) BOOL runBackgroundAnimation;
@property (weak, nonatomic) IBOutlet UIImageView *currentlyShowingBackground;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *allBackgrounds;

@end

@implementation ShelbyEntranceViewController {
    UIAlertView *_alertView;
    CGFloat _initialLogoVerticalSpaceToTopConstant, _properLogoVerticalSpaceToTopConstant,
            _initialGetStartedVerticalSpaceToBottomConstant, _properGetStartedVerticalSpaceToBottomConstant,
            _initialLoginVerticalSpaceToBottomConstant, _properLoginVerticalSpaceToBottomConstant;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _runBackgroundAnimation = NO;
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.getStartedButton.backgroundColor = kShelbyColorGreen;
    self.getStartedButton.layer.cornerRadius = 5.f;
    self.loginButton.backgroundColor = kShelbyColorBlue;
    self.loginButton.layer.cornerRadius = 5.f;
    
    //initial/proper position constants
    _properLogoVerticalSpaceToTopConstant = self.logoVerticalSpaceToTop.constant;
    _initialLogoVerticalSpaceToTopConstant = _properLogoVerticalSpaceToTopConstant - 500.f;
    _properGetStartedVerticalSpaceToBottomConstant = self.getStartedVerticalSpaceToBottom.constant;
    _initialGetStartedVerticalSpaceToBottomConstant = _properGetStartedVerticalSpaceToBottomConstant - 1500.f;
    _properLoginVerticalSpaceToBottomConstant = self.loginVerticalSpaceToBottom.constant;
    _initialLoginVerticalSpaceToBottomConstant = _properLoginVerticalSpaceToBottomConstant - 1000.f;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidSucceed:) name:kShelbyNotificationUserSignupDidSucceed object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userSignupDidFail:) name:kShelbyNotificationUserSignupDidFail object:nil];
    
    srand48(time(0));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setInitialViewStates];
    [self.view layoutIfNeeded];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenEntrance];
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEntranceStart];
    
    [self setButtonsEnabled:YES];
    
    [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:8.0 options:(UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        
        [self setProperViewStates];
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        self.runBackgroundAnimation = YES;
    }];
}

- (void)animateDisappearanceWithCompletion:(void (^)())completion
{
    self.runBackgroundAnimation = NO;
    
    [UIView animateWithDuration:1.0 delay:0 usingSpringWithDamping:.8 initialSpringVelocity:8.0 options:(UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState) animations:^{
        
        [self setInitialViewStates];
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

//aka "off screen"
- (void)setInitialViewStates
{
    [self.getStartedSpinner stopAnimating];
    self.logoVerticalSpaceToTop.constant = _initialLogoVerticalSpaceToTopConstant;
    self.getStartedVerticalSpaceToBottom.constant = _initialGetStartedVerticalSpaceToBottomConstant;
    self.loginVerticalSpaceToBottom.constant = _initialLoginVerticalSpaceToBottomConstant;
    
    for (UIView *backgroundView in self.allBackgrounds) {
        backgroundView.alpha = 0.f;
    }
}

//aka "on screen"
- (void)setProperViewStates
{
    self.logoVerticalSpaceToTop.constant = _properLogoVerticalSpaceToTopConstant;
    self.getStartedVerticalSpaceToBottom.constant = _properGetStartedVerticalSpaceToBottomConstant;
    self.loginVerticalSpaceToBottom.constant = _properLoginVerticalSpaceToBottomConstant;
    
    self.currentlyShowingBackground.alpha = 1.f;
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

#pragma mark - Target-Action

- (IBAction)getStartedTapped:(id)sender {
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEntranceUserTapGetStarted];
    
    [self.getStartedSpinner startAnimating];
    [self.getStartedButton setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    [self setButtonsEnabled:NO];
    [[ShelbyDataMediator sharedInstance] createAnonymousUser];
    //result via notifications, registered above
}

- (IBAction)loginTapped:(id)sender {
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEntranceUserTapLogin];
    
    [self.brain presentUserLogin];
}

#pragma mark - Notifications

- (void)userSignupDidSucceed:(NSNotification *)notification
{
    User *anonUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    [self.brain proceedWithAnonymousUser:anonUser];
}

- (void)userSignupDidFail:(NSNotification *)notification
{
    _alertView = [[UIAlertView alloc] initWithTitle:@"Couldn't Get Started" message:@"Please try again in a minute.  Sorry." delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil];
    [_alertView show];
    
    double delayInSeconds = 5.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setButtonsEnabled:YES];
    });
}

#pragma mark - Helpers

- (void)setButtonsEnabled:(BOOL)enabled
{
    self.getStartedButton.enabled = enabled;
    self.getStartedButton.alpha = enabled ? 1.f : 0.3;
    self.loginButton.enabled = enabled;
    self.loginButton.alpha = enabled ? 1.f : 0.3;
    if (enabled) {
        [self.getStartedSpinner stopAnimating];
        [self.getStartedButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }
}

- (void)setRunBackgroundAnimation:(BOOL)runBackgroundAnimation
{
    if (_runBackgroundAnimation != runBackgroundAnimation) {
        _runBackgroundAnimation = runBackgroundAnimation;
        
        if (_runBackgroundAnimation) {
            [self stepBackgroundAnimation];
        }
    }
}

- (void)stepBackgroundAnimation
{
    if (self.runBackgroundAnimation) {
        NSMutableArray *hiddenBackgrounds = [self.allBackgrounds mutableCopy];
        [hiddenBackgrounds removeObject:self.currentlyShowingBackground];
        UIImageView *nextBackground = hiddenBackgrounds[arc4random_uniform([hiddenBackgrounds count])];
        nextBackground.alpha = 1.f;
        [self.view insertSubview:nextBackground belowSubview:self.currentlyShowingBackground];
        
        [UIView animateWithDuration:5.0f animations:^{
            self.currentlyShowingBackground.alpha = 0.f;
            
        } completion:^(BOOL finished) {
            self.currentlyShowingBackground = nextBackground;
            if (finished) {
                [self stepBackgroundAnimation];
            }
        }];
        
    } else {
        //we've been asked to stop, do nothing
    }
}

@end
