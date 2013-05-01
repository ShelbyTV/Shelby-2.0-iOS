//
//  ShelbyBrain.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrain.h"

#define kShelbyChannelsStaleTime 600 //10 minutes

@interface ShelbyBrain()
@property (nonatomic, strong) NSArray *channels; //of DisplayChannel
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
        
    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] > kShelbyChannelsStaleTime){
        [[ShelbyDataMediator sharedInstance] fetchChannels];
    }
    
}

#pragma mark - ShelbyDataMediatorDelegate
-(void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached
{
    if(!cached){
        self.channelsLoadedAt = [NSDate date];
    }
    //TODO be smart about settings browseVC.channels
    //self.browseVC.channels = channels;
}

-(void)fetchChannelsDidCompleteWithError
{
    //TODO: show error
}

@end
