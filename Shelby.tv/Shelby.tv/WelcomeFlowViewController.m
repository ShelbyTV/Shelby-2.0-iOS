//
//  WelcomeFlowViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/17/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeFlowViewController.h"

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

    [self.view addSubview:self.parallaxView];
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

- (IBAction)previewWasTapped:(id)sender {
    //TODO: enable saving status
    //    [[NSUserDefaults standardUserDefaults] setInteger:ShelbyWelcomeFlowStatusComplete forKey:kShelbyWelcomeFlowStatusKey];
    //    [[NSUserDefaults standardUserDefaults] synchronize]
    [self.delegate welcomeFlowDidTapPreview:self];
}

@end
