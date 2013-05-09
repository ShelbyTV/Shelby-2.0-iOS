//
//  ShelbyBrain.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrain.h"
#import "DisplayChannel.h"
#import "ShelbyModel.h"

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
    self.homeVC.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    self.homeVC.masterDelegate = self;
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
- (void)loginUserDidCompleteWithError:(NSString *)errorMessage
{
    [self.homeVC userLoginFailedWithError:errorMessage];
}

- (void)loginUserDidCompleteWithUser:(User *)user
{
    [self.homeVC setCurrentUser:user];
}

- (void)facebookConnectDidCompleteWithUser:(User *)user
{
    [self.homeVC setCurrentUser:user];
}

- (void)facebookConnectDidCompleteWithError:(NSString *)errorMessage
{
    [self.homeVC connectToFacebookFailedWithError:errorMessage];
}

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
    DLog(@"TODO: handle fetch channels did complete with error %@", error);
}

//channelEntries filled with ShelbyModel (specifically, a DashboardEntry or Frame)
-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                    with:(NSArray *)channelEntries fromCache:(BOOL)cached
{
    NSArray *curEntries = [self.homeVC entriesForChannel:channel];
    if(curEntries){
        ShelbyArrayMergeInstructions mergeInstructions = [self instructionsToMerge:channelEntries into:curEntries];
        if(mergeInstructions.shouldMerge){
            NSArray *newChannelEntries = [channelEntries subarrayWithRange:mergeInstructions.range];
            [self.homeVC addEntries:newChannelEntries toEnd:mergeInstructions.append ofChannel:channel];
        } else {
           //full subset, nothing to do
        }
    } else {
        [self.homeVC setEntries:channelEntries forChannel:channel];
    }
    
    if(!cached){
        [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
        [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:NO];
    }
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    //TODO: show error
    [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
    [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:NO];
    DLog(@"TODO: handle fetch channels did complete with error %@", error);
}

#pragma mark - Helper Methods
- (NSInteger)nextChannelForDirection:(BOOL)up
{
    NSArray *channels = self.homeVC.channels;
    NSUInteger numberOfChannels = [channels count];
    // KP KP: TODO: deal with the case that the channel not found
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
    // KP KP: TODO: prevent animated twice here and NOT in ShelbyHome. ---> same goes to Close animation
    
    self.currentChannel = channel;
    
    NSInteger index = [self.homeVC indexOfItem:item inChannel:channel];
    if (index == NSNotFound) {
        // KP KP: TODO: what is the channel have no videos at all? Deal with that case
        index = 0;
    }
    [self.homeVC animateLaunchPlayerForChannel:channel atIndex:index];
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

- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    //OPTIMIZE: could be smarter, don't ALWAYS send this fetch if we have an outstanding fetch
    [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:YES];
    [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel sinceEntry:entry];
}

#pragma mark - Helpers

typedef struct _ShelbyArrayMergeInstructions {
    bool shouldMerge;
    bool append;
    NSRange range;
} ShelbyArrayMergeInstructions;

#define NEWER_THAN_INTO_ARRAY NSNotFound

//NB: objects in array must repond to selector shelbyID
- (ShelbyArrayMergeInstructions)instructionsToMerge:(NSArray *)newArray into:(NSArray *)curArray
{
    ShelbyArrayMergeInstructions instructions;
    
    NSUInteger firstEntryIndex = [curArray indexOfObject:newArray[0]];
    NSUInteger lastEntryIndex = [curArray indexOfObject:[newArray lastObject]];
    if(firstEntryIndex == NSNotFound){
        //shelbyID is a MongoID which starts with timestamp
        if([[newArray[0] shelbyID] compare:[curArray[0] shelbyID]] == NSOrderedDescending){
            //first new element > first old element
            firstEntryIndex = NEWER_THAN_INTO_ARRAY;
        } else {
            firstEntryIndex = [curArray count];
        }
    }
    if(lastEntryIndex == NSNotFound){
        if([[[curArray lastObject] shelbyID] compare:[[newArray lastObject] shelbyID]] == NSOrderedDescending){
            //last old element > last new element
            lastEntryIndex = [curArray count];
        } else {
            lastEntryIndex = NEWER_THAN_INTO_ARRAY;
        }
        
    }
    
    if(firstEntryIndex == NEWER_THAN_INTO_ARRAY){
        if(lastEntryIndex == NEWER_THAN_INTO_ARRAY){
            //full prepend
            instructions.shouldMerge = YES;
            instructions.append = NO;
            instructions.range = NSMakeRange(0, [newArray count]);
        } else {
            //partial prepend
            instructions.shouldMerge = YES;
            instructions.append = NO;
            NSUInteger overlapIdx = [newArray indexOfObject:curArray[0]];
            //djs debug code
            if(overlapIdx == NSNotFound){
                DLog(@"firstEntryIndex:%lu, lastEntryIndex:%lu", (unsigned long)firstEntryIndex, (unsigned long)lastEntryIndex);
                DLog(@"curArray: %@ // newArray: %@", curArray, newArray);
                NSAssert(false, @"v1-expected an overlap, what's up?");
            }
            instructions.range = NSMakeRange(0, overlapIdx);
        }
    } else if(firstEntryIndex == [curArray count]){
        //full append
        instructions.shouldMerge = YES;
        instructions.append = YES;
        instructions.range = NSMakeRange(0, [newArray count]);
    } else if(lastEntryIndex < [curArray count]){
        //complete subset
        instructions.shouldMerge = NO;
    } else {
        //partial append
        instructions.shouldMerge = YES;
        instructions.append = YES;
        NSUInteger overlapIdx = [newArray indexOfObject:[curArray lastObject]];
        //djs debug code
        if(overlapIdx == NSNotFound){
            DLog(@"firstEntryIndex:%lu, lastEntryIndex:%lu", (unsigned long)firstEntryIndex, (unsigned long)lastEntryIndex);
            DLog(@"curArray: %@ // newArray: %@", curArray, newArray);
            NSAssert(false, @"v2-expected an overlap, what's up?");
        }
        instructions.range = NSMakeRange(overlapIdx+1, [newArray count]-(overlapIdx+1));
    }
    
    return instructions;
}

#pragma mark - ShelbyHomeDelegate
- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password
{
    [[ShelbyDataMediator sharedInstance] loginUserWithEmail:email password:password];
}

- (void)logoutUser
{
    [[ShelbyDataMediator sharedInstance] logout];
    [self.homeVC setCurrentUser:nil];
}

- (void)connectToFacebook
{
    [[ShelbyDataMediator sharedInstance] openFacebookSessionWithAllowLoginUI:YES];
}

- (void)connectToTwitter
{
//    [[ShelbyDataMediator sharedInstance] connectTwitterWithViewController:self.homeVC];
}

@end
