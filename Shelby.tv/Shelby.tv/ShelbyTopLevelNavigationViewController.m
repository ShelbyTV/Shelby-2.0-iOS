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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fetchNotificationEntriesDidCompletelNotification:)
                                                 name:kShelbyBrainFetchNotificationEntriesDidCompleteNotification
                                               object:nil];
    
    self.notificationCenterVC = [[ShelbyNotificationCenterViewController alloc] initWithNibName:@"ShelbyNotificationCenterView" bundle:nil];
    self.notificationCenterVC.delegate = self;

    self.headerView = [[NSBundle mainBundle] loadNibNamed:@"SignupHeaderView" owner:self options:nil][0];
    self.headerView.delegate = self;
    
    self.topLevelTable.backgroundColor = kShelbyColorDarkGray;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.topLevelTable reloadData];
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
        cell.titleLabel.text = @"My Activity";
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
        DisplayChannel *userStream =  [DisplayChannel fetchChannelWithDashboardID:self.currentUser.userID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        ShelbyStreamInfoViewController *userStreamVC = [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:userStream];
        userStreamVC.userEducationVC = [ShelbyUserEducationViewController newStreamUserEducationViewController];
        
    } else if (indexPath.row == 1) {
        //Me
        DisplayChannel *userStream =  [DisplayChannel fetchChannelWithRollID:self.currentUser.publicRollID
                                                                   inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        ShelbyUserInfoViewController *userInfoVC = [ [UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfile"];
        
        [(ShelbyNavigationViewController *)self.navigationController pushUserProfileViewController:userInfoVC];
        userInfoVC.user = self.currentUser;
        [userInfoVC setupStreamInfoDisplayChannel:userStream];
        
    } else if (indexPath.row == 2) {
        //Explore
        [self goToFeaturedChannel];
        
    } else if (indexPath.row == 3) {
        //Channels
        BrowseChannelsTableViewController *channelsVC = [[UIStoryboard storyboardWithName:@"BrowseChannels" bundle:nil] instantiateInitialViewController];
        [self.navigationController pushViewController:channelsVC animated:YES];
        channelsVC.userEducationVC = [ShelbyUserEducationViewController newChannelsUserEducationViewController];
        
    } else if (indexPath.row == 4) {
        //Notifications
        self.notificationCenterVC.title = @"Notifications";
        [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.notificationCenterVC];
        
    } else if (indexPath.row == 5) {
        //Settings
        self.settingsVC = [[SettingsViewController alloc] initWithUser:self.currentUser];
        self.settingsVC.title = @"Settings";
        self.settingsVC.delegate = self;
        [(ShelbyNavigationViewController *)self.navigationController pushViewController:self.settingsVC];
    }

    [self.topLevelTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self.currentUser isAnonymousUser]) {
        return 80.0;
    } else {
        return 0;
    }
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.headerView;
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

    [((ShelbyNavigationViewController *)self.navigationController) presentViewController:signupVC animated:YES completion:nil];
    
}
@end
