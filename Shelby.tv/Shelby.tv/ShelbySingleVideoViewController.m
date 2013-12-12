//
//  ShelbySingleVideoViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbySingleVideoViewController.h"

@interface ShelbySingleVideoViewController ()
@property (nonatomic, strong) UIActivityIndicatorView *loadingSpinner;

@end

@implementation ShelbySingleVideoViewController

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

- (CGFloat)swapAnimationTime
{
    return 0;
}

- (void)setupNavBarView
{
    self.navBar = [[UIView alloc] init];
    [self.view addSubview:self.navBar];
    self.navBar.backgroundColor =  [UIColor colorWithPatternImage:[UIImage imageNamed:@"top-nav-bkgd.png"]];
    self.navBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[navBar]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[navBar(44)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"navBar":self.navBar}]];
    
    UILabel *videoLabel = [[UILabel alloc] initWithFrame:CGRectMake(50, 10, self.view.frame.size.width-100, 24)];
    videoLabel.textAlignment = NSTextAlignmentCenter;
    videoLabel.text = @"Video";
    videoLabel.backgroundColor = [UIColor clearColor];
    videoLabel.textColor = kShelbyColorWhite;
    videoLabel.font = kShelbyFontH3;
    videoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.navBar addSubview:videoLabel];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-90-[videoLabel]-90-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"videoLabel":videoLabel}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[videoLabel(24)]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"videoLabel":videoLabel}]];
    
    // Close Button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(5, 2, 40, 40);
    [closeButton setTitleColor:kShelbyColorGray forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(dismissSingleVideoView) forControlEvents:UIControlEventTouchUpInside];
    [closeButton setImage:[UIImage imageNamed:@"close-icon"] forState:UIControlStateNormal];
    closeButton.titleLabel.font = kShelbyFontH4Bold;
    [self.navBar addSubview:closeButton];
    
    
    //loading spinner
    _loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _loadingSpinner.hidesWhenStopped = YES;
    [self.navBar addSubview:_loadingSpinner];
    _loadingSpinner.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[spinner]-15-|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"spinner":_loadingSpinner}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-13-[spinner]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"spinner":_loadingSpinner}]];
    
}

- (void)dismissSingleVideoView
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
