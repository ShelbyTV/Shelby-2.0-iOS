//
//  WelcomeFlowViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowViewController.h"
#import "WelcomeFlowUFOMothershipViewController.h"

NSString * const kShelbyWelcomeFlowStatusKey = @"welcome_flow_status";

typedef NS_ENUM(NSInteger, ShelbyWelcomeFlowStatus)
{
    ShelbyWelcomeFlowStatusUnstarted, // 0
    ShelbyWelcomeFlowStatusComplete
};

@interface WelcomeFlowViewController ()
@property (strong, nonatomic) STVParallaxView *parallaxView;
@property (strong, nonatomic) IBOutlet UIView *page1;
@property (strong, nonatomic) IBOutlet UIView *page2;
@property (strong, nonatomic) IBOutlet UIView *page3;
@property (strong, nonatomic) IBOutlet UIView *page4;
@property (strong, nonatomic) IBOutlet UIView *background;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (strong, nonatomic) WelcomeFlowUFOMothershipViewController *ufoMothership;
@end

@implementation WelcomeFlowViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // 1) Parallax view: content
    //strong pointers are wired up to all the views in this xib, no need to retain this array
    [[NSBundle mainBundle] loadNibNamed:@"WelcomeFlowViews" owner:self options:nil];
    UIView *parallaxForegroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 4*self.view.frame.size.width, self.view.frame.size.height)];
    self.page1.frame = CGRectMake(0*self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [parallaxForegroundView addSubview:self.page1];
    self.page2.frame = CGRectMake(1*self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [parallaxForegroundView addSubview:self.page2];
    self.page3.frame = CGRectMake(2*self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [parallaxForegroundView addSubview:self.page3];
    self.page4.frame = CGRectMake(3*self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height);
    [parallaxForegroundView addSubview:self.page4];

    // 2) Parallax view: configuration
    self.parallaxView = [[STVParallaxView alloc] initWithFrame:self.view.frame];
    //move background left a bit to account for pulling
    self.background.frame = CGRectMake(-100, 0, self.background.frame.size.width, self.background.frame.size.height);
    self.parallaxView.backgroundContent = self.background;
    self.parallaxView.foregroundContent = parallaxForegroundView;
    self.parallaxView.parallaxRatio = 0.5;

    [self.view insertSubview:self.parallaxView belowSubview:self.pageControl];

    // 3) Page Control
    self.parallaxView.delegate = self;
    [self.pageControl addTarget:self action:@selector(pageChangeRequest:) forControlEvents:UIControlEventValueChanged];

    // 4) UFO
    self.ufoMothership = [[WelcomeFlowUFOMothershipViewController alloc] initWithNibName:@"WelcomeFlowMothership" bundle:nil];
    // NB: we may want to insert the mothership BETWEEN the parallax foreground and background
    // Not sure just yet.  Depends on design...
    // If the design HAS NO PARALLAX BACKGROUND then i can just put this below the parallax view...
    [self.view insertSubview:self.ufoMothership.view belowSubview:self.parallaxView];
    self.ufoMothership.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mothership]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"mothership":self.ufoMothership.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mothership]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"mothership":self.ufoMothership.view}]];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

+ (bool)isWelcomeComplete
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kShelbyWelcomeFlowStatusKey] == ShelbyWelcomeFlowStatusComplete;
}

- (IBAction)signupWasTapped:(id)sender
{
    [self welcomeFlowComplete];
    [self.delegate welcomeFlowDidTapSignup:self];
}

- (IBAction)loginWasTapped:(id)sender
{
    [self welcomeFlowComplete];
    [self.delegate welcomeFlowDidTapLogin:self];
}

- (IBAction)previewWasTapped:(id)sender
{
    [self welcomeFlowComplete];
    [self.delegate welcomeFlowDidTapPreview:self];
}

- (void)welcomeFlowComplete
{
    [[NSUserDefaults standardUserDefaults] setInteger:ShelbyWelcomeFlowStatusComplete forKey:kShelbyWelcomeFlowStatusKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - STVParallaxViewDelegate

- (void)parallaxDidChange:(STVParallaxView *)parallaxView
{
    [self.ufoMothership controllingContentOffsetDidChange:parallaxView.foregroundContentOffset];
}

- (void)didScrollToPage:(NSUInteger)page
{
    self.pageControl.currentPage = page;
    [self.ufoMothership pageDidChange:page];
}

#pragma mark - UIPageControl Delegate

- (void)pageChangeRequest:(UIPageControl *)pageControl
{
    [self.parallaxView scrollToPage:pageControl.currentPage];
    // I'd prefer to perform the following in a completion block, but parallaxView uses scrollView's
    // -setContentOffset:animated: and scrollView has no other API for this :[
    // * Here's some crazy shit: performSelector:withObject: wants an object, No Shit! But I want to send a primitive...
    // * This is a cool way to do just that using NSInvocation
    NSInvocation *invoc = [NSInvocation invocationWithMethodSignature:[WelcomeFlowViewController instanceMethodSignatureForSelector:@selector(didScrollToPage:)]];
    [invoc setSelector:@selector(didScrollToPage:)];
    [invoc setTarget:self];
    NSUInteger curPage = pageControl.currentPage;
    [invoc setArgument:&curPage atIndex:2];
    [invoc performSelector:@selector(invoke) withObject:nil afterDelay:0.3];
}

@end
