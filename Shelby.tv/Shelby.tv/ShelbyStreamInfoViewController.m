//
//  ShelbyStreamInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamInfoViewController.h"
#import "ShelbyBrain.h"

@interface ShelbyStreamInfoViewController ()
@property (nonatomic, strong) NSMutableArray *channelEntries;
@property (nonatomic, strong) NSMutableArray *deduplicatedEntries;
@end

@implementation ShelbyStreamInfoViewController

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
                                             selector:@selector(fetchEntriesDidCompleteForChannelNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchEntriesDidCompleteForChannelWithErrorNotification:)
                                                 name:kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDisplayChannel:(DisplayChannel *)displayChannel
{
    if (self.displayChannel != displayChannel) {
        _displayChannel = displayChannel;
        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:displayChannel sinceEntry:nil];
    }
}


- (void)fetchEntriesDidCompleteForChannelNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    
    if (channel != self.displayChannel) {
        return;
    }
    
    NSArray *channelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    
    if (!channelEntries) {
        channelEntries = @[];
    }
    
    // TODO: Dedupes + don't just add
    if (channel.channelID) {
        [self.channelEntries addObjectsFromArray:channelEntries];
    }
    
    if (self.shouldInitializeVideoReel) {
        [self.videoReelVC loadChannel:self.displayChannel withChannelEntries:channelEntries andAutoPlay:YES];
        self.shouldInitializeVideoReel = NO;
    }
}


- (void)fetchEntriesDidCompleteForChannelWithErrorNotification:(NSNotification *)notification
{
    // TODO
}

@end
