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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setupBackgroundImageForOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    self.imageToAnimate.alpha = 0;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:2 animations:^{
        self.imageToAnimate.alpha = 1;
    }];
}

- (void)setupBackgroundImageForOrientation:(UIInterfaceOrientation)orientation
{
    NSString *largeIphoneImage = nil;
    if (kShelbyFullscreenHeight > 480) {
        largeIphoneImage = @"-568h";
    } else {
        largeIphoneImage = @"";
    }
    
    NSString *imageName = nil;
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        imageName = [NSString stringWithFormat:@"bkgd-landscape%@.png", largeIphoneImage];
    } else {
        imageName = [NSString stringWithFormat:@"no-content-bkgd%@.png", largeIphoneImage];;
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:imageName]];
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    [self setupBackgroundImageForOrientation:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
