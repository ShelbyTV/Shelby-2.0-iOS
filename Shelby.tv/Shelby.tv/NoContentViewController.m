//
//  NoContentViewController.m
//  Shelby.tv
//
//  Created by Keren on 7/25/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "NoContentViewController.h"

@interface NoContentViewController ()
@property (nonatomic, weak) IBOutlet UIImageView *imageToAnimate;

@end

@implementation NoContentViewController

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
    self.imageToAnimate.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:2 animations:^{
        self.imageToAnimate.alpha = 1;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
