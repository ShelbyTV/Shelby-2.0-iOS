//
//  ShelbyViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyViewController.h"

#import "GAI.h"

@interface ShelbyViewController ()

@end

@implementation ShelbyViewController

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

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
{
    [ShelbyAnalyticsClient sendEventWithCategory:category action:action label:label];
}

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
          withNicknameAsLabel:(BOOL)nicknameAsLabel
{
    [ShelbyAnalyticsClient sendEventWithCategory:category action:action nicknameAsLabel:nicknameAsLabel];
}

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value
{
    [ShelbyAnalyticsClient sendEventWithCategory:category action:action label:label value:value];
}


@end
