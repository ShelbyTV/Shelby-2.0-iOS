//
//  PageViewController.m
//  Shelby.tv
//
//  Created by Keren on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "PagesViewController.h"
#import "MeViewController.h"
#import "PagesModel.h"

@interface PagesViewController ()

@property (strong, nonatomic) PagesModel *model;

@end

@implementation PagesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];

    UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    pageViewController.delegate = self;
    _model = [[PagesModel alloc] init];
    pageViewController.dataSource = self.model;
    
    PageViewController *startingViewController = [self.model viewControllerAtIndex:0];

    NSArray *viewControllers = @[startingViewController];
    [pageViewController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
    
    
    [self addChildViewController:pageViewController];
    [self.view addSubview:pageViewController.view];
    
    // Set the page view controller's bounds using an inset rect so that self's view is visible around the edges of the pages.
    CGRect pageViewRect = self.view.bounds;
    pageViewController.view.frame = pageViewRect;
    
    [pageViewController didMoveToParentViewController:self];
    
    // Add the page view controller's gesture recognizers to the book view controller's view so that the gestures are started more easily.
    self.view.gestureRecognizers = pageViewController.gestureRecognizers;

}


@end
