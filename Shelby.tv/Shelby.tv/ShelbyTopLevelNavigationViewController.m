//
//  ShelbyTopLevelNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopLevelNavigationViewController.h"
#import "BrowseChannelsTableViewController.h"
#import "DisplayChannel+Helper.h"
#import "ShelbyBrain.h"
#import "ShelbyDataMediator.h"
#import "ShelbyNavigationViewController.h"

// TODO: DRY
//NSString * const kShelbyCommunityChannelID = @"521264b4b415cc44c9000001";

@interface ShelbyTopLevelNavigationViewController ()
@property (nonatomic, weak) IBOutlet UITableView *topLevelTable;
@property (nonatomic, strong) SettingsViewController *settingsVC;
@property (nonatomic, strong) ShelbyNotificationCenterViewController *notificationCenterVC;
@end


@implementation ShelbyTopLevelNavigationViewController

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

    self.title = @"Shelby TV";
    [self.topLevelTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TopLevelNavigationCell"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fetchNotificationEntriesDidCompletelNotification:) name:kShelbyBrainFetchNotificationEntriesDidCompleteNotification object:nil];
    
    self.notificationCenterVC = [[ShelbyNotificationCenterViewController alloc] initWithNibName:@"ShelbyNotificationCenterView" bundle:nil];
    self.notificationCenterVC.delegate = self;
    
    self.topLevelTable.backgroundColor = kShelbyColorDarkGray;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setCurrentUser:(User *)currentUser
{
    if (_currentUser != currentUser) {
        _currentUser = currentUser;
        [self.topLevelTable reloadData];
    }
}

- (void)fetchNotificationEntriesDidCompletelNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSArray *notificationEntries = userInfo[kShelbyBrainChannelEntriesKey];
    
    [self.notificationCenterVC setNotificationEntries:notificationEntries];
}

#pragma mark UITableDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.currentUser) {
        return 3;
    } else {
        return 6;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TopLevelNavigationCell" forIndexPath:indexPath];
    cell.contentView.backgroundColor = kShelbyColorDarkGray;
    cell.textLabel.backgroundColor = kShelbyColorDarkGray;
    cell.textLabel.textColor = kShelbyColorWhite;
    cell.textLabel.font = kShelbyFontH3Bold;
    
    if (!self.currentUser) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"My Activity";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Explore";
        } else {
            cell.textLabel.text = @"Login";
        }
    } else if (indexPath.row == 0) {
        cell.textLabel.text = @"Stream";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"My Activity";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Explore";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Channels";
    } else if (indexPath.row == 4) {
        cell.textLabel.text = @"Notifications";
    } else {
        cell.textLabel.text = @"Settings";
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentUser) {
        if (indexPath.row == 0) {
            DisplayChannel *userStream =  [DisplayChannel fetchChannelWithDashboardID:self.currentUser.userID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:userStream];
        } else if (indexPath.row == 1) {
            DisplayChannel *userStream =  [DisplayChannel fetchChannelWithRollID:self.currentUser.publicRollID
                                                                            inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:userStream];
        } else if (indexPath.row == 2) {
            [self goToFeaturedChannel];
        } else if (indexPath.row == 3) {
            BrowseChannelsTableViewController *channelsVC = [[UIStoryboard storyboardWithName:@"BrowseChannels" bundle:nil] instantiateInitialViewController];
            [self.navigationController pushViewController:channelsVC animated:YES];
            
        } else if (indexPath.row == 4) {
            self.notificationCenterVC.title = @"Notifications";
            [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.notificationCenterVC];
        } else if (indexPath.row == 5) {
            self.settingsVC = [[SettingsViewController alloc] initWithUser:self.currentUser];
            self.settingsVC.title = @"Settings";
            self.settingsVC.delegate = self;
            [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.settingsVC];
        }
    } else {
        if (indexPath.row == 0) {
            DisplayChannel *userStream =  [DisplayChannel channelForOfflineLikesInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:userStream];
        } else if (indexPath.row == 1) {
            [self goToFeaturedChannel];
        } else {
            [((ShelbyNavigationViewController *)self.navigationController).topContainerDelegate loginUser];

        }
    }

    [self.topLevelTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)goToFeaturedChannel
{
    DisplayChannel *communityChannel =  [DisplayChannel fetchChannelWithDashboardID:@"521264b4b415cc44c9000001"
                                         
                                                                          inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:communityChannel];
 
}

#pragma mark - SettingsViewDelegate
- (void)logoutUser
{
    self.currentUser = nil;
    [((ShelbyNavigationViewController *)self.navigationController).topContainerDelegate logoutUser];
}

- (void)connectToFacebook
{
    [[ShelbyDataMediator sharedInstance] userAskForFacebookPublishPermissions];
}

- (void)connectToTwitter
{
    User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    NSString *token = nil;
    if (user) {
        token = user.token;
    }
    [[TwitterHandler sharedInstance] authenticateWithViewController:self.navigationController withDelegate:self andAuthToken:token];
}

- (void)enablePushNotifications:(BOOL)enable
{
    
}

#pragma mark - ShelbyNotificationDelegate Methods
- (void)unseenNotificationCountChanged
{
//    [self.navBarVC setUnseenNotificationCount:self.notificationCenterVC.unseenNotifications];
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [((ShelbyNavigationViewController *)self.navigationController).topContainerDelegate userProfileWasTapped:userID];
}

- (void)videoWasTapped:(NSString *)videoID
{
//    [((ShelbyNavigationViewController *)self.navigationController).topContainerDelegate  openVideoViewForDashboardID:videoID];
}
@end
