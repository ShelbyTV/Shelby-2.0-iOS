//
//  ShelbyNotificationCenterViewController.m
//  Shelby.tv
//
//  Created by Keren on 12/16/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyNotificationCenterViewController.h"
#import "DashboardEntry+Helper.h"
#import "FollowNotificationViewCell.h"
#import "LikeNotificationViewCell.h"
#import "ShelbyBrain.h"
#import "ShelbyModelArrayUtility.h"
#import "UIImageView+AFNetworking.h"

@interface ShelbyNotificationCenterViewController ()
@property (nonatomic, weak) IBOutlet UITableView *notificationTable;
@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, assign) NSInteger unseenNotifications;
@end

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.unseenNotifications = 0;
    [self.notificationTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setNotificationEntries:(NSArray *)notificationEntries
{
    if (!self.notifications) {
        self.notifications = [@[] mutableCopy];
    }
    // KP KP: TODO: make sure notfications are for current user. For that ShelbyHomeVC will have to pass in the Current User
    for (DashboardEntry *dashboardEntry in notificationEntries) {
        if (![self.notifications containsObject:dashboardEntry]) {
            self.unseenNotifications++;
            [self.notifications addObject:dashboardEntry];
        }
    }
    
    [self.notificationTable reloadData];
}



#pragma mark - UITableViewDataSource Delegate Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DashboardEntry *dashboardEntry = self.notifications[indexPath.row];

    if (NO) {  // Placeholder for where follow notifications will go to
        FollowNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FollowNotificationCell" forIndexPath:indexPath];
        return cell;
    } else {
        LikeNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LikeNotificationCell" forIndexPath:indexPath];
        NSString *likerName = dashboardEntry.actor.name;
        if (!likerName) {
            likerName = @"Somebody";
        }
        if ([dashboardEntry typeOfEntry] == DashboardEntryTypeLike) {
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

        NSMutableURLRequest *avatarRequest = [NSMutableURLRequest requestWithURL:[dashboardEntry.actor avatarURL]];
        [cell.avatar setImageWithURLRequest:avatarRequest placeholderImage:[UIImage imageNamed:@"avatar-blank.png"] success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
            if (image) {
                cell.avatar.image = image;
            }
        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        }];

        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}


@end
