//
//  XViewController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/4/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "MyViewController.h"

@interface MyViewController ()

@end

@implementation MyViewController

#pragma mark - Memory Management Methods
- (void)dealloc
{
    // Release NSNotifications
}

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    
    if ( [self isViewLoaded] && ![self.view window] ) {
        
        // Release your view
        
    }
    
}

#pragma mark - Initialization
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if ( self ) {
        
        // Your custom initialization goes here
        
    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

#pragma mark - Action Methods
// Declare your IBActions Here

#pragma mark - Public Methods
// Declare your Public

#pragma mark - Private Methods

@end
