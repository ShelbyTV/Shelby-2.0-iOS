//
//  ShelbyCurrentlyOnViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/10/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyCurrentlyOnViewController.h"
#import "AFNetworking.h"
#import "DisplayChannel+Helper.h"
//TODO Refactor kShelbyVideoReelDidChangePlaybackEntityNotification out of SPVideoReel.h?
#import "SPVideoReel.h"
#import "ShelbyVideoContainer.h"

@interface ShelbyCurrentlyOnViewController ()
@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (strong, nonatomic) id<ShelbyVideoContainer> currentEntity;
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
    self.currentEntity = userInfo[kShelbyVideoReelEntityKey];

    self.videoTitleLabel.text = [self.currentEntity containedVideo].title;
    [self tryNormalThumbnailForCurrentEntity];
}

- (void)tryNormalThumbnailForCurrentEntity
{
    id<ShelbyVideoContainer> entityRequested = self.currentEntity;
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:[self.currentEntity containedVideo].thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest imageProcessingBlock:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (self.currentEntity == entityRequested) {
            self.thumbnailImageView.image = image;
        } else {
            //currently on changed
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        //do anything?
    }] start];
}

@end
