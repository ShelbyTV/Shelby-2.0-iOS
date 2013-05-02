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
    //TODO: detect sleep time and remove player if it's been too long
        
    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] < kShelbyChannelsStaleTime){
        if(!self.browseVC.channels){
            //djs TODO: start big channels activity indicator
        }
        [[ShelbyDataMediator sharedInstance] fetchChannels];
    }
    
}

- (void)populateChannelsWithActivityIndicator:(BOOL)showSpinner
{
    for (DisplayChannel *channel in self.browseVC.channels){
        [self populateChannel:channel withActivityIndicator:showSpinner];
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
    
    NSArray *curChannels = self.browseVC.channels;
    if(!curChannels){
        self.browseVC.channels = channels;
        //djs TODO: stop big channels activity indicator
        [self populateChannelsWithActivityIndicator:YES];
    } else {
        //caveat: changing a DisplayChannel attribute will not trigger an update
        //array needs to be different order/length to trigger update
        if(![channels isEqualToArray:curChannels]){
            self.browseVC.channels = channels;
            [self populateChannelsWithActivityIndicator:YES];
        } else {
            /* don't replace old channels */
        }
    }
    
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
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    //TODO: show error
}

@end
