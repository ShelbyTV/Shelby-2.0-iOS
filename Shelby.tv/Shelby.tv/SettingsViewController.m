//
//  SettingsViewController.m
//  Shelby.tv
//
//  Created by Keren on 4/24/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SettingsViewController.h"
#import "TwitterHandler.h"
#import "FacebookHandler.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *faceookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UILabel *fullname;

/// User interaction methods
- (IBAction)connectoToFacebook:(id)sender;
- (IBAction)connectoToTwitter:(id)sender;
- (IBAction)goToMyRoll:(id)sender;
- (IBAction)goToMyLikes:(id)sender;
- (IBAction)logout:(id)sender;

/// 
- (void)refreshSocialButtonStatus;
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
    // KP KP: TODO: Next line will crash in a Universal app.
    self.contentSizeForViewInPopover = CGSizeMake(332, 230);
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_pane.png"]]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self refreshSocialButtonStatus];
    
    // KP KP: TODO: need to store user full name in CoreData
    NSString *name = [[NSUserDefaults standardUserDefaults] objectForKey:@"userFullname"];
    if (name) {
        [self.fullname setText:name];
    } else {
        [self.fullname setText:@""];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// KP KP: TODO: for now not really checking the user object. Need to Check that. Maybe also add username to the coredata object
- (void)refreshSocialButtonStatus
{
    NSString *facebookName = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyFacebookUserFullName];
    if (facebookName) {
        [self.faceookButton setTitle:[NSString stringWithFormat:@"%@", facebookName] forState:UIControlStateDisabled];
        [self.faceookButton setEnabled:NO];
    } else {
        [self.faceookButton setEnabled:YES];
    }
    
    NSString *twitterName = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyTwitterUsername];
    if (twitterName) {
        [self.twitterButton setTitle:[NSString stringWithFormat:@"@%@", twitterName] forState:UIControlStateDisabled];
        [self.twitterButton setEnabled:NO];
    } else {
        [self.twitterButton setEnabled:YES];
    }
}


#pragma mark - User Interaction Methods
- (IBAction)goToMyLikes:(id)sender
{
    [self.parent launchMyLikesPlayer];
    [self.parent dismissPopover];
}


- (IBAction)goToMyRoll:(id)sender
{
    [self.parent launchMyRollPlayer];
    [self.parent dismissPopover];
}

// KP KP: TODO: Right now doing FB/TW connect EVERY single time. Need to do it only if user is not connected
- (IBAction)connectoToFacebook:(id)sender
{
    [[FacebookHandler sharedInstance] openSession:YES];
    [self.parent dismissPopover];
}

- (IBAction)connectoToTwitter:(id)sender
{
    [[TwitterHandler sharedInstance] authenticateWithViewController:self.parent];
    [self.parent dismissPopover];
}


- (IBAction)logout:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                                        message:@"Are you sure you want to logout?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Logout", nil];
    
    [alertView show];
}

// KP KP: TODO: until we have a better consistent stay with the backend,
+ (void)cleanupSession
{
    // Reset user state (Authorization NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserAuthorized];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultUserIsAdmin];
    
    // Reset app mode state (Secred Mode NSUserDefaults)
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineModeEnabled];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kShelbyDefaultOfflineViewModeEnabled];
    
    // KP KP: TODO: need to store user full name in CoreData
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"userFullname"]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"userFullname"];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];

    [[FacebookHandler sharedInstance] facebookCleanup];
    [[TwitterHandler sharedInstance] twitterCleanup];
}


#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate logout];
        [SettingsViewController cleanupSession];
        [self.parent dismissPopover];
    }
}

@end
