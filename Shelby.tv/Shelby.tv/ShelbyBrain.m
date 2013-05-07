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
    [self.homeVC setBrowseDelegete:self];
    //TODO: detect sleep time and remove player if it's been too long
        
    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] < kShelbyChannelsStaleTime){
        if(!self.homeVC.channels){
            [self.homeVC.channelsLoadingActivityIndicator startAnimating];
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
        [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:YES];
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
    } else {
        //caveat: changing a DisplayChannel attribute will not trigger an update
        //array needs to be different order/length to trigger update
        if(![channels isEqualToArray:curChannels]){
            self.homeVC.channels = channels;
        } else {
            /* don't replace old channels */
        }
    }
    
    if(cached){
        //could populate channels w/ cached data only here, and then API request data in else block
    } else {
        [self.homeVC.channelsLoadingActivityIndicator stopAnimating];
        [self populateChannels];
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
    //djs TODO: set these smartly, don't just overwrite everything
    [self.homeVC setEntries:channelEntries forChannel:channel];
    if(!cached){
        [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
    }
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    //TODO: show error
    [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
}

#pragma mark - ShelbyBrowseProtocol Methods
- (void)launchChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [self.homeVC launchPlayerForChannel:channel atIndex:index];
}

- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item
{
    // Need to find the item pressed and 
    [self launchChannel:channel atIndex:0];
}

@end
