//
//  BrowseChannelsTableViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "BrowseChannelsTableViewController.h"
#import "BrowseChannelCell.h"
#import "DisplayChannel+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyDataMediator.h"
#import "ShelbyNavigationViewController.h"

@interface BrowseChannelsTableViewController ()
@property (strong, nonatomic) NSArray *channels;
@property (strong, nonatomic) User *currentUser;
@property (assign, nonatomic) NSUInteger followCount;
@end

@implementation BrowseChannelsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.followCount = 0;

    [[ShelbyDataMediator sharedInstance] fetchFeaturedChannelsWithCompletionHandler:^(NSArray *channels, NSError *error) {
        if (channels) {
            self.channels = [channels copy];
            self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
            [self calculateFollowCount];
            [self.tableView reloadData];
        } else {
            //TODO iPad: handle error
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.channels ? self.channels.count : 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ChannelCell";
    BrowseChannelCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    cell.user = self.currentUser;
    cell.roll = ((DisplayChannel *)self.channels[indexPath.row]).roll;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DisplayChannel *selectedChannel = self.channels[indexPath.row];
 
    //TODO iPad: i think we need to push a different kind of view controller
    // or at least a slightly different setup (need mockups)
    [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:selectedChannel];
}

#pragma mark - Target-Action

- (IBAction)followTappedInCell:(UIView *)sender {
    while (![sender isKindOfClass:[BrowseChannelCell class]]) {
        sender = sender.superview;
    }
    BrowseChannelCell *cell = (BrowseChannelCell *)sender;
    
    DisplayChannel *channel = self.channels[[self.tableView indexPathForCell:cell].row];
    if ([self.currentUser isFollowing:channel.roll.rollID]) {
        [self doUnfollow:channel];
    } else {
        [self doFollow:channel];
    }
    
    [cell updateFollowStatus];
}

#pragma mark - Helpers

- (void)doFollow:(DisplayChannel *)channelToFollow
{
    [[ShelbyDataMediator sharedInstance] followRoll:channelToFollow.roll.rollID];
    self.followCount++;
}

- (void)doUnfollow:(DisplayChannel *)channelToUnfollow
{
    [[ShelbyDataMediator sharedInstance] unfollowRoll:channelToUnfollow.roll.rollID];
    self.followCount--;
}

- (void)calculateFollowCount
{
    for (DisplayChannel *ch in self.channels) {
        if ([self.currentUser isFollowing:ch.roll.rollID]) {
            self.followCount++;
        }
    }
}

@end
