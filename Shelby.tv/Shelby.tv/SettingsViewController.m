//
//  SettingsViewController.m
//  Shelby.tv
//
//  Created by Keren on 4/24/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsCell.h"
#import "TwitterHandler.h"
#import "FacebookHandler.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation SettingsViewController

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
    
    [self.tableView registerClass:[SettingsCell class] forCellReuseIdentifier:@"SettingsCell"];
	// Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1) {
        return 2;
    } else {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

// KP KP: TODO: for now not really checking the user object. Need to Check that. Maybe also add username to the coredata object
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
    
    NSString *text = nil;
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            text = @"My Likes";
        } else {
            text = @"My Roll";
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyFacebookUserFullName];
            if (name) {
                text = [NSString stringWithFormat:@"Facebook user: %@", name];
            } else {
                text = @"Connect to Facebook";
            }
        } else {
            NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyTwitterUsername];
            if (name) {
                text = [NSString stringWithFormat:@"Twitter user: @%@", name];
            } else {
                text = @"Connect to Twitter";
            }
        }
    } else {
        text = @"Logout";
    }
    
    [cell.textLabel setText:text];
    return cell;
}

#pragma mark - UITableViewDelegate Methods
// KP KP: TODO: Right now doing FB/TW connect EVERY single time. Need to do it only if user is not connected
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];

    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // My Likes
        } else {
            // My Rool
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [[FacebookHandler sharedInstance] openSession:YES];
        } else {
            [[TwitterHandler sharedInstance] authenticateWithViewController:self.parent];
        }
    } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                                                message:@"Are you sure you want to logout?"
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Logout", nil];
            
            [alertView show];
        // Logout
        return;
    }
    
    [self.parent dismissPopover];
}


#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate logout];
        [self.parent dismissPopover];
    }
}

@end
