//
//  ViewController.m
//  Shelby Beta
//
//  Created by Keren on 11/11/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "ViewController.h"
#import "UIColor+ColorWithHexAndAlpha.h"

@interface ViewController ()
@property (nonatomic, weak) IBOutlet UIButton *getShelby;

- (IBAction)downloadApp:(id)sender;
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.getShelby.backgroundColor = kShelbyColorGreen;
    self.getShelby.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (IBAction)downloadApp:(id)sender
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.apple.com/us/app/appName/id732244981?mt=8"]];
}

@end
