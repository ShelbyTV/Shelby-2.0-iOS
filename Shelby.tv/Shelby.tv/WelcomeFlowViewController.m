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

@end

@implementation WelcomeFlowViewController

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
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

+ (bool)isWelcomeComplete
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kShelbyWelcomeFlowStatusKey] == ShelbyWelcomeFlowStatusComplete;
}

- (IBAction)completeTestTapped:(id)sender {
    //TODO: enable saving status
//    [[NSUserDefaults standardUserDefaults] setInteger:ShelbyWelcomeFlowStatusComplete forKey:kShelbyWelcomeFlowStatusKey];
//    [[NSUserDefaults standardUserDefaults] synchronize]
    [self.delegate welcomeFlowDidTapPreview:self];
}


@end
