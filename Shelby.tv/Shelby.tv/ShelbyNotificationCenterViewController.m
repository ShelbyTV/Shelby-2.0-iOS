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

@interface ShelbyNotificationCenterViewController ()
@property (nonatomic, weak) IBOutlet UITableView *notificationTable;
@property (nonatomic, strong) NSMutableArray *notifications;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource Delegate Methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
//    return [self.notifications count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    DashboardEntry *dashboardEntry = self.notifications[indexPath.row];
    
    if (YES) { // if type Like
        LikeNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LikeNotificationCell" forIndexPath:indexPath];
        return cell;
    } else {
        FollowNotificationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FollowNotificationCell" forIndexPath:indexPath];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    DashboardEntry *dashboardEntry = self.notifications[indexPath.row];
    

}


@end
