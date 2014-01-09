//
//  ShelbyTopLevelNavigationViewController.m
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyTopLevelNavigationViewController.h"
#import "DisplayChannel+Helper.h"
#import "SettingsViewController.h"
#import "ShelbyDataMediator.h"
#import "ShelbyNavigationViewController.h"

// TODO: DRY
//NSString * const kShelbyCommunityChannelID = @"521264b4b415cc44c9000001";

@interface ShelbyTopLevelNavigationViewController ()
@property (nonatomic, strong) IBOutlet UITableView *topLevelTable;
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

    [self.topLevelTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"TopLevelNavigationCell"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.currentUser) {
        return 3;
    } else {
        return 5;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TopLevelNavigationCell" forIndexPath:indexPath];
    if (!self.currentUser) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"My Activity";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Featured";
        } else {
            cell.textLabel.text = @"Login";
        }
    } else if (indexPath.row == 0) {
        cell.textLabel.text = @"Stream";
    } else if (indexPath.row == 1) {
        cell.textLabel.text = @"My Activity";
    } else if (indexPath.row == 2) {
        cell.textLabel.text = @"Featured";
    } else if (indexPath.row == 3) {
        cell.textLabel.text = @"Notifications";
    } else {
        cell.textLabel.text = @"Settings";
    }
    return cell;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (indexPath.row == 4) {
        SettingsViewController *settingsVC = [[SettingsViewController alloc] initWithNibName:@"SettingsView-iPhone" bundle:nil];
        [(ShelbyNavigationViewController *)self.navigationController pushViewController:settingsVC];
    } else {
        DisplayChannel *communityChannel =  [DisplayChannel fetchChannelWithDashboardID:@"521264b4b415cc44c9000001"
                                             
                                                                              inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        [(ShelbyNavigationViewController *)self.navigationController pushViewControllerForChannel:communityChannel shouldInitializeVideoReel:YES];
    }
}



@end
