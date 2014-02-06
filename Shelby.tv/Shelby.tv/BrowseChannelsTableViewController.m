//
//  BrowseChannelsTableViewController.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "BrowseChannelsTableViewController.h"
#import "BrowseChannelCell.h"
#import "BrowseChannelsHeaderView.h"
#import "DisplayChannel+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyDataMediator.h"
#import "ShelbyNavigationViewController.h"

@interface BrowseChannelsTableViewController ()
@property (strong, nonatomic) NSArray *channels;
@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) BrowseChannelsHeaderView *headerView;
@property (nonatomic, assign) BOOL shouldFireFetchStreamRequestOnDisappear;
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
    
    [[ShelbyDataMediator sharedInstance] fetchFeaturedChannelsWithCompletionHandler:^(NSArray *channels, NSError *error) {
        if (channels) {
            self.channels = [channels copy];
            self.currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
            self.headerView = [[NSBundle mainBundle] loadNibNamed:@"BrowseChannelsHeaderView" owner:self options:nil][0];
            [self calculateFollowCount];
            if (self.headerView.hitTargetFollowCount) {
                self.headerView = nil;
            }
            [self.tableView reloadData];
        } else {
            //TODO iPad: handle error
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.userEducationVC referenceView:self.view willAppearAnimated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenChannels];
    self.shouldFireFetchStreamRequestOnDisappear = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.userEducationVC referenceViewWillDisappear:animated];
    
    if (self.shouldFireFetchStreamRequestOnDisappear) {
        DisplayChannel *currentUsersStream =  [DisplayChannel fetchChannelWithDashboardID:self.currentUser.userID
                                                                                inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:currentUsersStream sinceEntry:nil];
    }
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
    [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:selectedChannel titleOverride:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.headerView) {
        return self.headerView.bounds.size.height;
    } else {
        return 0;
    }
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
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
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsFollowChannel];
    
    [[ShelbyDataMediator sharedInstance] followRoll:channelToFollow.roll.rollID];
    //fire and forget (although actual request will update this correctly)
    [self.currentUser didFollowRoll:channelToFollow.roll.rollID];
    [self.headerView increaseFollowCount];
    [self updateUserEducation];
    self.shouldFireFetchStreamRequestOnDisappear = YES;
}

- (void)doUnfollow:(DisplayChannel *)channelToUnfollow
{
    [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsUnfollowChannel];
    
    [[ShelbyDataMediator sharedInstance] unfollowRoll:channelToUnfollow.roll.rollID];
    //fire and forget (although actual request will update this correctly)
    [self.currentUser didUnfollowRoll:channelToUnfollow.roll.rollID];
    [self.headerView decreaseFollowCount];
}

- (void)calculateFollowCount
{
    [self.headerView resetFollowCount];
    for (DisplayChannel *ch in self.channels) {
        if ([self.currentUser isFollowing:ch.roll.rollID]) {
            [self.headerView increaseFollowCount];
        }
    }
    [self updateUserEducation];
}

- (void)updateUserEducation
{
    if ([self.headerView hitTargetFollowCount]) {
        [self.userEducationVC userHasBeenEducatedAndViewShouldHide:YES];
    }
}

@end
