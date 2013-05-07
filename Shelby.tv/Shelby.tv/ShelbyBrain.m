//
//  ShelbyBrain.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrain.h"
#import "DisplayChannel.h"

#define kShelbyChannelsStaleTime -600 //10 minutes

@interface ShelbyBrain()
@property (nonatomic, strong) NSDate *channelsLoadedAt;
@property (nonatomic, strong) DisplayChannel *currentChannel;
@end

@implementation ShelbyBrain

//TODO: assert singletone pattern in init method

- (void)setup
{
    [ShelbyDataMediator sharedInstance].delegate = self;
}


- (void)handleDidBecomeActive
{
    self.homeVC.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUser];
    self.homeVC.brainAsDelegate = self;
    //TODO: detect sleep time and remove player if it's been too long
        
    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] < kShelbyChannelsStaleTime){
        if(!self.homeVC.channels){
            //djs TODO: start big channels activity indicator
        }
        [[ShelbyDataMediator sharedInstance] fetchChannels];
    }
    
}

- (void)populateChannels
{
    //djs TODO: be smart about loading channels and activity indicator
    //pull each channel from the browseVC
    // if it's nil, show spinner and fetch
    // if it's old, show spinner and fetch
    // if it's new, no spinner (and fetch?)
    
    for (DisplayChannel *channel in self.homeVC.channels){
        [self populateChannel:channel withActivityIndicator:YES];
    }
}

- (void)populateChannel:(DisplayChannel *)channel withActivityIndicator:(BOOL)showSpinner
{
    if(showSpinner){
        //djs TODO: show single-channel spinner in self.browseVC
    }
    
    [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel sinceEntry:nil];
}

#pragma mark - ShelbyDataMediatorDelegate
-(void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached
{
    //cached channels, stale
    //cached channels, fresh  <--- doesn't get here
    
    //api channels, with cache update
    //api channels, without cache update
    
    NSArray *curChannels = self.homeVC.channels;
    if(!curChannels){
        self.homeVC.channels = channels;
        //djs TODO: stop big channels activity indicator
    } else {
        //caveat: changing a DisplayChannel attribute will not trigger an update
        //array needs to be different order/length to trigger update
        if(![channels isEqualToArray:curChannels]){
            self.homeVC.channels = channels;
        } else {
            /* don't replace old channels */
        }
    }
    
    [self populateChannels];
    
    if(!cached){
        self.channelsLoadedAt = [NSDate date];
    }
}

-(void)fetchChannelsDidCompleteWithError:(NSError *)error
{
    //TODO: show error
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                    with:(NSArray *)channelEntries fromCache:(BOOL)cached
{
    //TODO: something
    [self.homeVC setEntries:channelEntries forChannel:channel];
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    //TODO: show error
}

#pragma mark - Helper Methods
- (NSInteger)nextChannelForDirection:(BOOL)up
{
    NSArray *channels = self.homeVC.channels;
    NSUInteger numberOfChannels = [channels count];
    NSInteger currentChannelIndex = [channels indexOfObject:self.currentChannel];
    NSInteger next = up ? -1 : 1;
    NSInteger nextChannel = currentChannelIndex + next;
    if (nextChannel < 0) {
        nextChannel = numberOfChannels + nextChannel;
    } else if (nextChannel == numberOfChannels) {
        nextChannel = 0;
    }
    
    return nextChannel;
}

- (void)launchChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    self.currentChannel = channel;
    [self.homeVC launchPlayerForChannel:channel atIndex:index];
}

#pragma mark - ShelbyBrowseProtocol Methods
- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item
{
    // KP KP: TODO: Need to find the item pressed and
    self.currentChannel = channel;
    [self.homeVC animateLaunchPlayerForChannel:channel atIndex:0];
}

#pragma mark - SPVideoReelProtocol Methods
- (void)userDidSwitchChannelForDirectionUp:(BOOL)up;
{
    [self.homeVC dismissPlayer];
    NSInteger nextChannel = [self nextChannelForDirection:up];
    [self launchChannel:self.homeVC.channels[nextChannel] atIndex:0];
}

- (void)userDidCloseChannel
{
    [self.homeVC animateDismissPlayerForChannel:self.currentChannel];
}

- (DisplayChannel *)displayChannelForDirection:(BOOL)up
{
    NSInteger nextChannel = [self nextChannelForDirection:up];
    
    return self.homeVC.channels[nextChannel];
}

- (void)videoDidFinishPlaying
{
    // TODO
}


@end
