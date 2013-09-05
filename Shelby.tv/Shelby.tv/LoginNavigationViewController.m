//
//  LoginNavigationViewController.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/18/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "LoginNavigationViewController.h"

@interface LoginNavigationViewController ()

@end

@implementation LoginNavigationViewController

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

    //NB: see AppDelegate for appearance proxy setup
    [self.navigationBar setBackgroundImage:[UIImage imageNamed:@"top-nav-bkgd"] forBarMetrics:UIBarMetricsDefault];
    [self.navigationBar setTitleTextAttributes:@{UITextAttributeTextColor: [UIColor whiteColor]}];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return NO;
}

@end
