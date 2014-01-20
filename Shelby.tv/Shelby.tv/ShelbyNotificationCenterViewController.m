//
//  ShelbyNotificationCenterViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNotificationCenterViewController.h"
#import "DashboardEntry+Helper.h"
#import "ShelbyBrain.h"
#import "ShelbyModelArrayUtility.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyNotificationCenterViewController ()
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopSpaceConstraint;
@property (nonatomic, weak) IBOutlet UITableView *notificationTable;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, assign) NSInteger unseenNotifications;
@end

NSString * const kShelbyNotificationCenterLastNotificationIDKey = @"kShelbyNotificationCenterLastNotificationIDKey";

@implementation ShelbyNotificationCenterViewController

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
    
    [self.notificationTable registerNib:[UINib nibWithNibName:@"LikeNotificationViewCell" bundle:nil] forCellReuseIdentifier:@"LikeNotificationCell"];
    [self.notificationTable registerNib:[UINib nibWithNibName:@"FollowNotificationViewCell" bundle:nil] forCellReuseIdentifier:@"FollowNotificationCell"];
    
    if (DEVICE_IPAD) {
        self.tableViewTopSpaceConstraint.constant = 0;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // KP KP: TODO: save last seen notification so we can have the number of notifications accurate 
    self.unseenNotifications = 0;
    
    if ([self.notifications count]) {
        NSString *lastSeenNotificationID = ((DashboardEntry *)self.notifications[0]).dashboardEntryID;
        [[NSUserDefaults standardUserDefaults] setObject:lastSeenNotificationID forKey:kShelbyNotificationCenterLastNotificationIDKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kShelbyNotificationCenterLastNotificationIDKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.delegate unseenNotificationCountChanged];
    [self.notificationTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setNotificationEntries:(NSArray *)notificationEntries
{
    // KP KP: TODO: make sure notfications are for current user. For that ShelbyHomeVC will have to pass in the Current User
    NSInteger currentUnseenNotifications = self.unseenNotifications;
    NSMutableArray *notificationsToAdd = [@[] mutableCopy];
    
    if (!self.notifications) {
        self.notifications = [@[] mutableCopy];
    }
    BOOL olderNotifications = NO;
    NSString *lastNotificationIDSeenByUser = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyNotificationCenterLastNotificationIDKey];
    for (DashboardEntry *dashboardEntry in notificationEntries) {
        if (![self.notifications containsObject:dashboardEntry]) {
            if (!olderNotifications && [lastNotificationIDSeenByUser isEqualToString:dashboardEntry.dashboardEntryID]) {
                olderNotifications = YES;
            }

            if (!olderNotifications) {
                self.unseenNotifications++;
            }
            
            [notificationsToAdd addObject:dashboardEntry];
        }
    }
    
    [notificationsToAdd addObjectsFromArray:self.notifications];
    self.notifications = notificationsToAdd;
    
    if (currentUnseenNotifications != self.unseenNotifications) {
        [self.delegate unseenNotificationCountChanged];
    }

    [self.notificationTable reloadData];
}

- (void)fetchAvatarForCell:(FollowNotificationViewCell *)cell withAvatarURL:(NSURL *)avatarURL
{
    NSMutableURLRequest *avatarRequest = [NSMutableURLRequest requestWithURL:avatarURL];
    [cell.avatar setImageWithURLRequest:avatarRequest placeholderImage:[UIImage imageNamed:@"avatar-blank.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        if (image) {
            cell.avatar.image = image;
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
    }];
}

- (void)viewUserInNotificationCell:(FollowNotificationViewCell *)cell
{
    if (cell.userID) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                              action:kAnalyticsUXTapUserProfileFromNotificationView
                                     nicknameAsLabel:YES];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapUserProfileFromNotificationView];
        
        [self.delegate userProfileWasTapped:cell.userID];
    }
}

#pragma mark - FollowNotificationDelegate
- (void)viewUserWasTappedForNotificationCell:(FollowNotificationViewCell *)cell
{
    [self viewUserInNotificationCell:cell];
}

#pragma mark - LikeNotificationDelegate
- (void)viewVideoWasTappedForNotificationCell:(LikeNotificationViewCell *)cell
{
    if (cell.dashboardID) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryPrimaryUX
                                              action:kAnalyticsUXTapVideoFromNotificationView
                                     nicknameAsLabel:YES];
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsTapVideoFromNotificationView];

        [self.delegate videoWasTapped:cell.dashboardID];
    }
}

#pragma mark - UITableViewDataSource Delegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DashboardEntry *dashboardEntry = self.notifications[indexPath.row];

    DashboardEntryType dashboardEntryType = [dashboardEntry typeOfEntry];
    
    NSString *likerName = dashboardEntry.actor.name;
    NSString *actorID = actorID = dashboardEntry.actor.userID;
    if (!likerName) {
        likerName = @"Somebody";
    }

    if (dashboardEntryType == DashboardEntryTypeFollow) {
        FollowNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FollowNotificationCell" forIndexPath:indexPath];
        cell.notificationText.text = [NSString stringWithFormat:@"%@ started following you", likerName];
        cell.userID = actorID;
        cell.delegate = self;
        [self fetchAvatarForCell:cell withAvatarURL:[dashboardEntry.actor avatarURL]];

        return cell;
    } else {
        LikeNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LikeNotificationCell" forIndexPath:indexPath];
        cell.userID = actorID;
        cell.dashboardID = dashboardEntry.dashboardEntryID;
        cell.delegate = self;
        
        if (dashboardEntryType == DashboardEntryTypeLike || dashboardEntryType == DashboardEntryTypeAnonymousLike) {
            cell.notificationText.text = [NSString stringWithFormat:@"%@ liked your video", likerName];
        } else { // Share
            cell.notificationText.text = [NSString stringWithFormat:@"%@ shared your video", likerName];
        }
 
        NSMutableURLRequest *thumbnailRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:dashboardEntry.frame.video.thumbnailURL]];
        // KP KP: TODO: default thumbnail
        [cell.thumbnail setImageWithURLRequest:thumbnailRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (image) {
                cell.thumbnail.image = image;
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        }];

        [self fetchAvatarForCell:cell withAvatarURL:[dashboardEntry.actor avatarURL]];
 
 
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    FollowNotificationViewCell *cell = (FollowNotificationViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [self viewUserInNotificationCell:cell];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}
@end
