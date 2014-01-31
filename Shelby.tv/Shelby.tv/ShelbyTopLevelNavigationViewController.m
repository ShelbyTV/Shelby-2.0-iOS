//
//  ShelbyTopLevelNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopLevelNavigationViewController.h"
#import "BrowseChannelsTableViewController.h"
#import "DashboardEntry+Helper.h"
#import "DisplayChannel+Helper.h"
#import "ShelbyBrain.h"
#import "ShelbyDataMediator.h"
#import "ShelbyNavigationViewController.h"
#import "ShelbySignupViewController.h"
#import "ShelbyUserEducationViewController.h"
#import "ShelbyUserInfoViewController.h"
#import "SignupHeaderView.h"
#import "TopLevelNavigationCell.h"
#import "User+Helper.h"

@interface ShelbyTopLevelNavigationViewController ()
@property (nonatomic, weak) IBOutlet UITableView *topLevelTable;
@property (nonatomic, strong) SettingsViewController *settingsVC;
@property (nonatomic, strong) ShelbyNotificationCenterViewController *notificationCenterVC;
@property (nonatomic, strong) SignupHeaderView *headerView;
@property (nonatomic, assign) BOOL shouldNavigateToUsersStreamOnAppear;
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

    self.title = @" "; //<-- so that nav shows "<" instead of "< Back"
    self.navigationItem.titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ipad-nav-title-logo"]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchNotificationEntriesDidCompletelNotification:)
                                                 name:kShelbyBrainFetchNotificationEntriesDidCompleteNotification
                                               object:nil];
    
    self.notificationCenterVC = [[ShelbyNotificationCenterViewController alloc] initWithNibName:@"ShelbyNotificationCenterView" bundle:nil];
    self.notificationCenterVC.delegate = self;

    self.headerView = [[NSBundle mainBundle] loadNibNamed:@"SignupHeaderView" owner:self options:nil][0];
    self.headerView.delegate = self;
    
    //start users in their stream on app launch (as opposed to top level navigation)
    self.shouldNavigateToUsersStreamOnAppear = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.topLevelTable reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (self.shouldNavigateToUsersStreamOnAppear && self.currentUser) {
        [self navigateToUsersStream];
        self.shouldNavigateToUsersStreamOnAppear = NO;
    }
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
    }
    [self.topLevelTable reloadData];
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
    STVAssert(self.currentUser, @"should have user, otherwise should be showing EntranceVC");
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TopLevelNavigationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TopLevelNavigationCell" forIndexPath:indexPath];
    
    if (indexPath.row == 0) {
        cell.titleLabel.text = @"Stream";
    } else if (indexPath.row == 1) {
        cell.titleLabel.text = @"My Profile";
    } else if (indexPath.row == 2) {
        cell.titleLabel.text = @"Explore";
    } else if (indexPath.row == 3) {
        cell.titleLabel.text = @"Channels";
    } else if (indexPath.row == 4) {
        cell.titleLabel.text = @"Notifications";
        [cell setBadge:self.notificationCenterVC.unseenNotifications];
    } else {
        cell.titleLabel.text = @"Settings";
    }
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    STVAssert(self.currentUser, @"must have user on iPad");
    
    if (indexPath.row == 0) {
        //Stream
        [self navigateToUsersStream];
        
    } else if (indexPath.row == 1) {
        //Me
        [self navigateToUsersActivity];
        
    } else if (indexPath.row == 2) {
        //Explore
        [self navigateToFeaturedChannel];
        
    } else if (indexPath.row == 3) {
        [self navigateToChannels];
        
    } else if (indexPath.row == 4) {
        [self navigateToNotifications];
        
    } else if (indexPath.row == 5) {
        [self navigateToSettings];
    }

    [self.topLevelTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 4 && [self.currentUser isAnonymousUser]) {
        //No Notifications for anonymous user
        return 0.f;
        
    } else {
        return tableView.rowHeight;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.currentUser isAnonymousUser]) {
        return 80.0;
    } else {
        //iOS 7 bug prevents 0 height from working inside navigation controller
        return 1.0;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self.currentUser isAnonymousUser]) {
        return self.headerView;
    } else {
        return nil;
    }
}

#pragma mark - SettingsViewDelegate

- (void)logoutUser
{
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

#pragma mark - ShelbyNotificationDelegate

- (void)unseenNotificationCountChanged
{
    [self.topLevelTable reloadData];
}

- (void)userProfileWasTapped:(NSString *)userID
{
    [((ShelbyNavigationViewController *)self.navigationController).topContainerDelegate userProfileWasTapped:userID];
}

- (void)videoWasTapped:(NSString *)videoID
{
    [[ShelbyDataMediator sharedInstance] fetchDashboardEntryWithID:videoID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext] completion:^(DashboardEntry *fetchedDashboardEntry) {
        
        if (fetchedDashboardEntry) {
            DisplayChannel *displayChannel =  [DisplayChannel channelForTransientEntriesWithID:videoID title:@"Video" inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            displayChannel.dashboard = fetchedDashboardEntry.dashboard;
            displayChannel.shouldFetchRemoteEntries = NO;
            ShelbyStreamInfoViewController *videoStreamVC = [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:displayChannel];
            videoStreamVC.singleVideoEntry = @[fetchedDashboardEntry];
            videoStreamVC.userEducationVC = [ShelbyUserEducationViewController newStreamUserEducationViewController];
        }
    }];
}

#pragma mark - SignupHeaderDelegate

- (void)signupUser
{
    ShelbySignupViewController *signupVC = [[ShelbySignupViewController alloc] initWithNibName:@"SignupView-iPad" bundle:nil];
    signupVC.modalPresentationStyle = UIModalPresentationPageSheet;
    signupVC.prepareForSignup = YES;
    [((ShelbyNavigationViewController *)self.navigationController) presentViewController:signupVC animated:YES completion:nil];
    
}

#pragma mark - Navigation Helpers

- (void)navigateToUsersStream
{
    DisplayChannel *userStream =  [DisplayChannel fetchChannelWithDashboardID:self.currentUser.userID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    ShelbyStreamInfoViewController *userStreamVC = [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:userStream];
    userStreamVC.userEducationVC = [ShelbyUserEducationViewController newStreamUserEducationViewController];
}

- (void)navigateToUsersActivity
{
    DisplayChannel *userStream =  [DisplayChannel fetchChannelWithRollID:self.currentUser.publicRollID
                                                               inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    ShelbyUserInfoViewController *userInfoVC = [ [UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfile"];
    
    userInfoVC.user = self.currentUser;
    [(ShelbyNavigationViewController *)self.navigationController pushUserProfileViewController:userInfoVC];
    [userInfoVC setupStreamInfoDisplayChannel:userStream];
}

- (void)navigateToFeaturedChannel
{
    DisplayChannel *communityChannel =  [DisplayChannel fetchChannelWithDashboardID:@"521264b4b415cc44c9000001"
                                         
                                                                          inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:communityChannel];
    
}

- (void)navigateToChannels
{
    BrowseChannelsTableViewController *channelsVC = [[UIStoryboard storyboardWithName:@"BrowseChannels" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:channelsVC animated:YES];
    channelsVC.userEducationVC = [ShelbyUserEducationViewController newChannelsUserEducationViewController];
}

- (void)navigateToNotifications
{
    self.notificationCenterVC.title = @"Notifications";
    [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.notificationCenterVC];
}

- (void)navigateToSettings
{
    self.settingsVC = [[SettingsViewController alloc] initWithUser:self.currentUser];
    self.settingsVC.title = @"Settings";
    self.settingsVC.delegate = self;
    [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.settingsVC];
}

@end
