//
//  SignupFlowNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/8/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFlowNavigationViewController.h"

@interface SignupFlowNavigationViewController ()
@property (nonatomic, strong) NSMutableDictionary *signupDictionary;
@end


@implementation SignupFlowNavigationViewController

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
    
    // Create an empty Signup Dictionary
    self.signupDictionary = [@{} mutableCopy];
    
    // Pass the dictionary to the SignupFlowVC
    SignupFlowViewController *rootVC = (SignupFlowViewController *)self.viewControllers[0];
    rootVC.signupDictionary = self.signupDictionary;


    // Using special background for back button.
//    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:[[UIImage imageNamed:@"navbar_back_button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 20, 0, 5)] forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(BOOL) shouldAutorotate {
    return YES;
}

#pragma mark - SignupFlowViewDelegate
- (void)connectToFacebook
{
    [self.signupDelegate connectToFacebook];
}

- (void)connectToTwitter
{
    [self.signupDelegate connectToTwitter];
}

@end
