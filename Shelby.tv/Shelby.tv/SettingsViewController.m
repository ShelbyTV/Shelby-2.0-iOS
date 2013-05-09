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
#import "ShelbyDataMediator.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *faceookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UILabel *fullname;

@property (nonatomic, strong) User *user;

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

- (id)initWithUser:(User *)user
{
    self = [super initWithNibName:@"SettingsView" bundle:nil];
    if (self) {
        _user = user;
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
    NSString *name = self.user.name;
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
    NSString *facebookName = self.user.facebookNickname;
    if (facebookName) {
        [self.faceookButton setTitle:[NSString stringWithFormat:@"%@", facebookName] forState:UIControlStateDisabled];
        [self.faceookButton setEnabled:NO];
    } else {
        [self.faceookButton setEnabled:YES];
    }
    
    NSString *twitterName = self.user.twitterNickname;
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
    if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(launchMyLikes)]) {
        [self.delegate launchMyLikes];
    }
}

- (IBAction)goToMyRoll:(id)sender
{
    if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(launchMyRoll)]) {
        [self.delegate launchMyRoll];
    }
}

- (IBAction)connectoToFacebook:(id)sender
{
    if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(connectToFacebook)]) {
        [self.delegate connectToFacebook];
    }
}

- (IBAction)connectoToTwitter:(id)sender
{
    if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(connectToTwitter)]) {
        [self.delegate connectToTwitter];
    }
//    [self.delegate dismissPopover];
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

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(logout)]) {
            [self.delegate logoutUser];
        }
   
        // KP KP: TODO: should be done nicely somewhere else
//        [SettingsViewController cleanupSession];
    }
}

@end
