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
#import "SettingsViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "UserDetailsCell.h"
#import "ShelbyAlertView.h"
#import "ShelbyDataMediator.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *faceookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UILabel *fullname;
@property (weak, nonatomic) IBOutlet UITableView *table;

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
    return [self initWithUser:user andNibName:@"SettingsView"];
}

- (id)initWithUser:(User *)user andNibName:(NSString *)nibName
{
    self = [super initWithNibName:nibName bundle:nil];
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
    
    [self.table registerNib:[UINib nibWithNibName:@"UserDetailsViewCell" bundle:nil] forCellReuseIdentifier:@"UserDetailsViewCell"];
    [self.table registerNib:[UINib nibWithNibName:@"SettingsViewCell" bundle:nil] forCellReuseIdentifier:@"SettingsViewCell"];
    
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SettingsCell"];
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
    NSString *facebookName = self.user.facebookName;
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
        if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(logoutUser)]) {
            [self.delegate logoutUser];
        }
   
        // KP KP: TODO: should be done nicely somewhere else
//        [SettingsViewController cleanupSession];
    }
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UserDetailsCell *cell = (UserDetailsCell *)[self.table dequeueReusableCellWithIdentifier:@"UserDetailsViewCell" forIndexPath:indexPath];
        cell.name.text = self.user.name;
        cell.userName.text = self.user.nickname;
        cell.avatar.layer.cornerRadius = 5;
        cell.avatar.layer.masksToBounds = YES;
        [cell.avatar setImageWithURL:self.user.avatarURL placeholderImage:nil];
        return cell;
    } else {
        SettingsViewCell *cell = (SettingsViewCell *)[self.table dequeueReusableCellWithIdentifier:@"SettingsViewCell" forIndexPath:indexPath];
        cell.secondaryTitle.hidden = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        if (indexPath.row == 1) {
            if (self.user.facebookNickname) {
                cell.mainTitle.text = @"Facebook:";
                cell.secondaryTitle.text = self.user.facebookNickname;
                cell.secondaryTitle.hidden = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                cell.mainTitle.text = @"Connect to Facebook";
            }
        } else if (indexPath.row == 2) {
            if (self.user.twitterNickname) {
                cell.mainTitle.text = @"Twitter:";
                cell.secondaryTitle.text = self.user.twitterNickname;
                cell.secondaryTitle.hidden = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
            } else {
                cell.mainTitle.text = @"Connect to Twitter";
            }
        } else if (indexPath.row == 3) {
            cell.mainTitle.text = @"Logout";
        } else if (indexPath.row == 4) {
            cell.mainTitle.text = @"Give us Feedback";
        } else {
            cell.mainTitle.text = @"Review us on App Store";
        }
        
        return cell;
    }
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 88;
    }
    
    return 45;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.table deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        [self connectoToTwitter:nil];
    } else if (indexPath.row == 2) {
        [self connectoToFacebook:nil];
    } else if (indexPath.row == 3) {
        [self logout:nil];
    } else if (indexPath.row == 4) {
        [self openMailComposer];
    } else if (indexPath.row == 5) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=467849037"]];        
    }

    // TODO: once we have the viewcontroller in the right place, make sure you register observers and refresh table to see that user has FB/TW user and logged out... etc.
}

- (void)openMailComposer {
    if([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"iPhone Feedback (%@-%@, %@ v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]]];
        [mailer setToRecipients:@[@"ipad@shelby.tv"]];
        [mailer setMessageBody:@"Believe it or not, a human will read this!  :-]\n\nWe really appreciate your ideas and feedback.  Feel free to write anything you want and we'll follow up with you." isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
    } else {
        [[[ShelbyAlertView alloc] initWithTitle:@"We'd Love to Hear from You!"
                                        message:@"Please email your feedback to us: ipad@shelby.tv"
                             dismissButtonTitle:@"Ok"
                                 autodimissTime:0
                                      onDismiss:nil]
         show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
