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
#import "DeviceUtilities.h"
#import "SettingsViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "UserDetailsCell.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyDataMediator.h"

@interface SettingsViewController ()
@property (weak, nonatomic) IBOutlet UIButton *faceookButton;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UILabel *fullname;
@property (weak, nonatomic) IBOutlet UITableView *table;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewTopVerticalSpaceConstraint;

@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;

/// User interaction methods
- (IBAction)connectoToFacebook:(id)sender;
- (IBAction)connectoToTwitter:(id)sender;
- (IBAction)goToMyRoll:(id)sender;
- (IBAction)logout:(id)sender;

/// 
- (void)refreshSocialButtonStatus;
@end

@implementation SettingsViewController

- (id)initWithUser:(User *)user
{
    return [self initWithUser:user andNibName:@"SettingsView-iPhone"];
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
//    self.contentSizeForViewInPopover = CGSizeMake(332, 230);
    [self.view setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"settings_pane.png"]]];
    
    [self.table registerNib:[UINib nibWithNibName:@"UserDetailsViewCell" bundle:nil] forCellReuseIdentifier:@"UserDetailsViewCell"];
    [self.table registerNib:[UINib nibWithNibName:@"SettingsViewCell" bundle:nil] forCellReuseIdentifier:@"SettingsViewCell"];
    [self.table registerNib:[UINib nibWithNibName:@"UserPreferencesViewCell" bundle:nil] forCellReuseIdentifier:@"UserPreferencesCell"];
    [self.table registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SettingsCell"];
    
    if (DEVICE_IPAD) {
        //working around iOS 7 bug where Grouped TableView inside a NavigationController does not respect
        //headers of height 0.  So I make the header height 1 and account for it here.
        self.tableViewTopVerticalSpaceConstraint.constant = -1;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [ShelbyAnalyticsClient trackScreen:kAnalyticsScreenSettings];

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

- (void)setUser:(User *)user
{
    _user = user;
    
    [self.table reloadData];
}

#pragma mark - User Interaction Methods
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
    UIAlertView *alertView;
    if ([self.user isAnonymousUser]) {
        alertView = [[UIAlertView alloc] initWithTitle:@"Already Have an Account?"
                                               message:@"You're using Shelby without an account. You can continue like this and convert to an account later, or log in with an existing account. Logging in will erase your progress so far."
                                              delegate:self
                                     cancelButtonTitle:@"Keep Using"
                                     otherButtonTitles:@"Erase & Log in", nil];
    } else {
        alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                               message:@"Are you sure you want to logout?"
                                              delegate:self
                                     cancelButtonTitle:@"Cancel"
                                     otherButtonTitles:@"Logout", nil];
    }
    
    [alertView show];
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(logoutUser)]) {
            [self.delegate logoutUser];
        }
    }
}

#pragma mark - UITableViewDataSource Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UserDetailsCell *cell = (UserDetailsCell *)[self.table dequeueReusableCellWithIdentifier:@"UserDetailsViewCell" forIndexPath:indexPath];
        cell.name.text = self.user.name;
        cell.userName.text = self.user.nickname;
        [cell.avatar setImageWithURL:self.user.avatarURL placeholderImage:[UIImage imageNamed:@"settings-default-avatar"]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    } else if (indexPath.row == 5) {
        UserPreferencesCell *cell = (UserPreferencesCell *)[self.table dequeueReusableCellWithIdentifier:@"UserPreferencesCell" forIndexPath:indexPath];
        cell.preferenceText.text = @"Push Notifications";
        [cell.preferenceSwitch setOn:[self.user.likeNotificationsIOS boolValue]];
        cell.delegate = self;
        //HACK: anonymous users aren't shown push notifications in settings
        cell.contentView.hidden = [self.user isAnonymousUser];
        return cell;
    } else {
        SettingsViewCell *cell = (SettingsViewCell *)[self.table dequeueReusableCellWithIdentifier:@"SettingsViewCell" forIndexPath:indexPath];
 
        cell.selectionStyle = UITableViewCellSelectionStyleGray;
        cell.secondaryTitle.hidden = YES;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.mainTitle.textColor = kShelbyColorMediumGray;
        if (indexPath.row == 1) {
            cell.mainTitle.textColor = kShelbyColorFacebookBlue;
            if (self.user.facebookNickname) {
                cell.mainTitle.text = @"Facebook:";
                cell.secondaryTitle.text = self.user.facebookNickname;
                cell.secondaryTitle.hidden = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                self.facebookConnected = YES;
            } else {
                cell.mainTitle.text = @"Connect to Facebook";
                self.facebookConnected = NO;
            }
        } else if (indexPath.row == 2) {
            cell.mainTitle.textColor = kShelbyColorTwitterBlue;
            if (self.user.twitterNickname) {
                cell.mainTitle.text = @"Twitter:";
                cell.secondaryTitle.text = [NSString stringWithFormat:@"@%@",self.user.twitterNickname];
                cell.secondaryTitle.hidden = NO;
                cell.accessoryType = UITableViewCellAccessoryNone;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                self.twitterConnected= YES;
            } else {
                cell.mainTitle.text = @"Connect to Twitter";
                self.twitterConnected= NO;
            }
            //HACK: anonymous users aren't shown twitter connect in settings
            cell.contentView.hidden = [self.user isAnonymousUser];
            
        } else if (indexPath.row == 3) {
            cell.mainTitle.text = @"Give us Feedback";
        } else if (indexPath.row == 4) {
            cell.mainTitle.text = @"Review us on App Store";
        } else if (indexPath.row == 6) {
            if ([self.user isAnonymousUser]) {
                cell.mainTitle.text = @"Login";
            } else {
                cell.mainTitle.text = @"Logout";
            }
        }
        
        return cell;
    }
}


#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        return 88;
    } else if ([self.user isAnonymousUser] && (indexPath.row == 5 || indexPath.row == 2)) {
        //hide push notifications and twitter connect for anonymous user
        return 0.f;
    }
    
    return 55;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    //just using grouping to get rid fo the fake empty cells, don't want actual header
    //accounting for this 1 pixel via top constraint
    return 1.f;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 5) {
        return NO;
    }
    
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.table deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1 && !self.facebookConnected) {
        [self connectoToFacebook:nil];
    } else if (indexPath.row == 2 && !self.twitterConnected) {
        [self connectoToTwitter:nil];
    } else if (indexPath.row == 3) {
        [self openMailComposer];
    } else if (indexPath.row == 4) {
        if ([DeviceUtilities isGTEiOS7]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://itunes.apple.com/app/id%@", SHELBY_APP_ID]]];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=%@", SHELBY_APP_ID]]];
        }
    } else if (indexPath.row == 6) {
        [self logout:nil];
    }
}

- (void)openMailComposer {
    if([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"iPhone Feedback (%@-%@, %@ v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]]];
        [mailer setToRecipients:@[@"iphone@shelby.tv"]];
        [mailer setMessageBody:@"Believe it or not, a human will read this!  :-]\n\nWe really appreciate your ideas and feedback.  Feel free to write anything you want and we'll follow up with you." isHTML:NO];
        [self presentViewController:mailer animated:YES completion:nil];
    } else {
        UIAlertView *alertView =  [[UIAlertView alloc] initWithTitle:@"We'd Love to Hear from You!" message:@"Please email your feedback to us: iphone@shelby.tv" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - UserPreferenecesCellDelegate Methods
- (void)userEnabledPushNotification:(BOOL)enable
{
    if ([self.delegate conformsToProtocol:@protocol(SettingsViewDelegate)] && [self.delegate respondsToSelector:@selector(enablePushNotifications:)]) {
        [self.delegate enablePushNotifications:enable];
    }
}
@end
