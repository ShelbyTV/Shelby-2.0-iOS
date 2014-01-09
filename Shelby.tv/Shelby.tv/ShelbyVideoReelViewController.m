//
//  ShelbyVideoReelViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyVideoReelViewController.h"
#import "SPVideoReel.h"

@interface ShelbyVideoReelViewController ()
@property (nonatomic, strong) SPVideoReel *videoReel;
@end

@implementation ShelbyVideoReelViewController

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

- (void)loadChannel:(DisplayChannel *)channel withChannelEntries:(NSArray *)channelEntries andAutoPlay:(BOOL)autoPlay
{
    //remove old video reel
    [self.videoReel shutdown];
    [self.videoReel willMoveToParentViewController:self];
    [self.videoReel removeFromParentViewController];
    
    //replace with a new video reel
    self.videoReel = [[SPVideoReel alloc] initWithChannel:channel andVideoEntities:channelEntries atIndex:0];
    [self addChildViewController:self.videoReel];
    self.videoReel.view.frame = self.view.bounds;
    [self.view addSubview:self.videoReel.view];
    [self.videoReel didMoveToParentViewController:self];

    if (autoPlay) {
        [self.videoReel playCurrentPlayer];
    }
}

@end
