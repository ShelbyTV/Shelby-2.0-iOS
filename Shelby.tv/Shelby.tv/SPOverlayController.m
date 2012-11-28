//
//  SPOverlayController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/28/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPOverlayController.h"
#import "SPOverlayView.h"
#import "SPVideoReel.h"

@interface SPOverlayController ()

@property (strong, nonatomic) SPVideoReel *videoReel;

- (void)homeButtonAction;

@end

@implementation SPOverlayController
@synthesize videoReel = _videoReel;
@synthesize videoFrames = _videoFrames;
@synthesize homeButton = _homeButton;

#pragma mark - Memory Management
- (void)dealloc
{
    self.homeButton = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Initialization Methods
- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
            videoReel:(SPVideoReel *)videoReel
          videoFrames:(NSMutableArray *)videoFrames
{
    
    if ( self == [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) {

        self.videoReel = videoReel;
        self.videoFrames = videoFrames;

    }
    
    return self;
}

#pragma mark - View Lifecycle Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.homeButton addTarget:self action:@selector(homeButtonAction) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - Action Methods
- (void)homeButtonAction
{
    DLog(@"Home Button Tapped");
    [self.videoReel dismissViewControllerAnimated:YES completion:nil];
}

@end