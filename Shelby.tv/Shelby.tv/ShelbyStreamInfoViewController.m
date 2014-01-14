//
//  ShelbyStreamInfoViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/8/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamInfoViewController.h"
#import "DashboardEntry.h"
#import "Frame.h"
#import "ShelbyBrain.h"

@interface ShelbyStreamInfoViewController ()
@property (nonatomic, strong) NSMutableArray *channelEntries;
@property (nonatomic, strong) NSMutableArray *deduplicatedEntries;
@property (nonatomic, weak) IBOutlet UITableView *entriesTable;
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

    self.channelEntries = [NSMutableArray new];
    
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

- (void)setEntries:(NSArray *)rawEntries forChannel:(DisplayChannel *)channel
{
    if (channel != self.displayChannel) {
        return;
    }
    
    if (rawEntries == nil) {
        rawEntries = @[];
    }
    
    if (_channelEntries != rawEntries) {
        _channelEntries = [rawEntries mutableCopy];
        
        //TODO iPad
        //TODO: dedupe
        self.deduplicatedEntries = _channelEntries;
        
        [self.videoReelVC setDeduplicatedEntries:self.channelEntries forChannel:self.displayChannel];
        
        [self.entriesTable reloadData];
    }
}

- (void)fetchEntriesDidCompleteForChannelNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    DisplayChannel *channel = userInfo[kShelbyBrainChannelKey];
    NSArray *channelEntries = userInfo[kShelbyBrainChannelEntriesKey];
    
    [self setEntries:channelEntries forChannel:channel];
}

- (void)fetchEntriesDidCompleteForChannelWithErrorNotification:(NSNotification *)notification
{
    // TODO
}

#pragma mark UITableDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.channelEntries count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ShelbyStreamEntryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"StreamEntry" forIndexPath:indexPath];
    id streamEntry = self.channelEntries[indexPath.row];
    Frame *videoFrame = nil;
    if ([streamEntry isKindOfClass:[DashboardEntry class]]) {
        videoFrame = ((DashboardEntry *)streamEntry).frame;
    } else if ([streamEntry isKindOfClass:[Frame class]]) {
        videoFrame = (Frame *)streamEntry;
    }
    
    cell.videoFrame = videoFrame;
    cell.delegate = self;
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.videoReelVC playChannel:self.displayChannel
          withDeduplicatedEntries:self.channelEntries
                          atIndex:indexPath.row];
}

#pragma mark ShelbyStreamEntryProtocol
- (void)shareVideoWasTappedForFrame:(Frame *)videoFrame
{
    
}

- (void)toggleLikeForFrame:(Frame *)videoFrame
{
    
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [self.delegate userProfileWasTapped:userID];
}

- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers
{
    [self.delegate openLikersViewForVideo:video withLikers:likers];
}



@end
