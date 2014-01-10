//
//  ShelbyCurrentlyOnViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyCurrentlyOnViewController.h"
#import "DisplayChannel+Helper.h"
//TODO Refactor kShelbyVideoReelDidChangePlaybackEntityNotification out of SPVideoReel.h?
#import "SPVideoReel.h"
#import "ShelbyVideoContainer.h"

@interface ShelbyCurrentlyOnViewController ()
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;

@end

@implementation ShelbyCurrentlyOnViewController

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

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playbackEntityDidChangeNotification:)
                                                 name:kShelbyVideoReelDidChangePlaybackEntityNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)playbackEntityDidChangeNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    //DisplayChannel *channel = userInfo[kShelbyVideoReelChannelKey];
    id<ShelbyVideoContainer> entity = userInfo[kShelbyVideoReelEntityKey];

    self.videoTitleLabel.text = [entity containedVideo].title;
}

@end
