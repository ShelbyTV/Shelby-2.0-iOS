//
//  ShelbyHomeViewController.m
//  Shelby.tv
//
//  Created by Keren on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyHomeViewController.h"
#import "AsynchronousFreeloader.h"
#import "BrowseViewController.h"
#import "DisplayChannel.h"
#import "ImageUtilities.h"
#import "SettingsViewController.h"
#import "ShelbyAlertView.h"
#import "SPVideoReel.h"
#import "TriageViewController.h"
#import "User+Helper.h"

@interface ShelbyHomeViewController ()
@property (nonatomic, weak) IBOutlet UIView *topBar;

@property (nonatomic, strong) UIView *settingsView;
@property (strong, nonatomic) UIPopoverController *settingsPopover;
@property (strong, nonatomic) AuthorizationViewController *authorizationVC;

@property (nonatomic, strong) BrowseViewController *browseVC;
@property (nonatomic, strong) TriageViewController *triageVC;
@property (nonatomic, strong) SPVideoReel *videoReel;
@property (nonatomic, assign) BOOL animationInProgress;

@end

@implementation ShelbyHomeViewController

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

    [self.topBar setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"topbar.png"]]];

    if (DEVICE_IPAD) {
        BrowseViewController *browseViewController = [[BrowseViewController alloc] initWithNibName:@"BrowseView" bundle:nil];

        [self setBrowseVC:browseViewController];
        [self addChildViewController:browseViewController];
        [browseViewController.view setFrame:CGRectMake(0, 44, browseViewController.view.frame.size.width, browseViewController.view.frame.size.height)];

        [self.view addSubview:browseViewController.view];
    
        [browseViewController didMoveToParentViewController:self];
    } else {
        TriageViewController *triageViewController = [[TriageViewController alloc] initWithNibName:@"TriageView" bundle:nil];
        [self setTriageVC:triageViewController];
        [self addChildViewController:triageViewController];
        [triageViewController.view setFrame:CGRectMake(0, 44, kShelbyFullscreenWidth, kShelbyFullscreenHeight-44-20)];
        
        [self.view addSubview:triageViewController.view];
        [self.view sendSubviewToBack:triageViewController.view];
    }
    
    [self setupSettingsView];
    
    [self.view bringSubviewToFront:self.channelsLoadingActivityIndicator];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (void)userLoginFailedWithError:(NSString *)errorMessage
{
    if (self.authorizationVC) {
        [self.authorizationVC userLoginFailedWithError:errorMessage];
    }
    [self setCurrentUser:nil];
}

- (void)connectToFacebookFailedWithError:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)connectToTwitterFailedWithError:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)setChannels:(NSArray *)channels
{
    _channels = channels;
    if (DEVICE_IPAD) {
        self.browseVC.channels = channels;
    } else {
        // KP KP: TODO - we need to send only one channel. this is a hack.
        if (channels && [channels count] > 0) {
            self.triageVC.triageChannel = channels[0];
        }
    }
}

- (void)removeChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        NSMutableArray *channels = [self.browseVC.channels mutableCopy];
        [channels removeObject:channel];
        self.browseVC.channels = channels;
    }
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        [self.browseVC setEntries:channelEntries forChannel:channel];
    } else {
        // KP KP: TODO: Again, this will change once we get correct channel to triage from backend
        self.triageVC.triageChannel = channel;
        [self.triageVC setItemsToTriage:channelEntries];
    }
    [self setPlayerEntriesForChannel:channel];
}

// For iPhone - KP KP: TODO: do differently.
- (NSInteger)indexOfDisplayedEntry:(id)entry
{
    NSArray *triageItems = [self.triageVC itemsToTriage];
    return [triageItems indexOfObject:entry];
}

// For iPad
- (NSInteger)indexOfDisplayedEntry:(id)entry inChannel:(DisplayChannel *)channel
{
    NSArray *dedupdEntries = [self deduplicatedEntriesForChannel:channel];
    return [dedupdEntries indexOfObject:entry];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    [self.browseVC addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel];
    [self setPlayerEntriesForChannel:channel];
}

- (void)setPlayerEntriesForChannel:(DisplayChannel *)channel
{
    if (self.videoReel) {
        NSArray *completeChannelEntries = [self.browseVC deduplicatedEntriesForChannel:channel];
        DisplayChannel *channelInPlayer = self.videoReel.channel;
        if ([channelInPlayer isEqual:channel]) {
            [self.videoReel setEntries:completeChannelEntries];
        }
    }
}

- (void)fetchDidCompleteForChannel:(DisplayChannel *)channel
{
    [self.browseVC fetchDidCompleteForChannel:channel];
}

- (NSArray *)entriesForChannel:(DisplayChannel *)channel
{
    return [self.browseVC entriesForChannel:channel];
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        return [self.browseVC deduplicatedEntriesForChannel:channel];
    } else {
        return [self.triageVC itemsToTriage];
    }
}

- (void)refreshActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    [self.browseVC refreshActivityIndicatorForChannel:channel shouldAnimate:shouldAnimate];
}

- (void)loadMoreActivityIndicatorForChannel:(DisplayChannel *)channel shouldAnimate:(BOOL)shouldAnimate
{
    [self.browseVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:shouldAnimate];
}

- (void)setMasterDelegate:(id)masterDelegate
{
    _masterDelegate = masterDelegate;
    if (DEVICE_IPAD) {
        self.browseVC.browseDelegate = masterDelegate;
    } else {
        self.triageVC.triageDelegate = masterDelegate;
    }
}

- (void)setCurrentUser:(User *)currentUser
{
    _currentUser = currentUser;
    
    if (currentUser) {
        [self dismissAuthorizationVC];
    }

    [self setupSettingsView];
}

// TODO: uncomment when we are ready to support login
// KP KP: TODO: maybe create a special UserAvatarView, pass a target to it.
- (void)setupSettingsView
{
    // KP KP: TODO: once fetching user done correctly, add the two targets. 
    [self.settingsView removeFromSuperview];
    if (self.currentUser) {
        // KP KP: TODO: bad alignment for iPad!
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(kShelbyFullscreenWidth - 70, 0, 60, 44)];
        UIImageView *userAvatar = [[UIImageView alloc] initWithFrame:CGRectMake(25, 7, 30, 30)];
        [userAvatar.layer setCornerRadius:5];
        [userAvatar.layer setMasksToBounds:YES];
        // KP KP: TODO: Use AFNetworking instead of AsynchronousFreeloader
        [AsynchronousFreeloader loadImageFromLink:self.currentUser.userImage
                                     forImageView:userAvatar
                                  withPlaceholder:nil
                                   andContentMode:UIViewContentModeScaleAspectFit];
        [self.settingsView addSubview:userAvatar];
        UIButton *settings = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
        [settings addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:settings];
    } else {
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(kShelbyFullscreenWidth - 70, 0, 120, 44)];
        UIButton *login = [UIButton buttonWithType:UIButtonTypeCustom];
        [login setFrame:CGRectMake(7, 7, 60, 30)];
        [login setBackgroundImage:[UIImage imageNamed:@"login.png"] forState:UIControlStateNormal];
        [login setTitle:@"Login" forState:UIControlStateNormal];
        [[login titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14]];
        [[login titleLabel] setTextColor:[UIColor whiteColor]];
        [login addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:login];
    }
    
    [self.view addSubview:self.settingsView];
}

- (void)showSettings
{
    if (DEVICE_IPAD) {
        if(!self.settingsPopover) {
            SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithUser:self.currentUser];
            
            _settingsPopover = [[UIPopoverController alloc] initWithContentViewController:settingsViewController];
            [self.settingsPopover setDelegate:self];
            [settingsViewController setDelegate:self];
        } else {
            SettingsViewController *settingsViewController = (SettingsViewController *)[self.settingsPopover contentViewController];
            if ([settingsViewController isKindOfClass:[SettingsViewController class]]) {
                settingsViewController.user = self.currentUser;
            }
        }
        
        [self.settingsPopover presentPopoverFromRect:self.settingsView.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else { // iPhone
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"My Roll", @"My Likes", @"Connect to Facebook", @"Connect to Twitter", @"Logout", nil];
        actionSheet.destructiveButtonIndex = 4;
        [actionSheet showInView:self.view];
    }
}


- (void)launchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self presentViewController:self.videoReel animated:NO completion:nil];
}

- (void)dismissPlayer
{
    [self.videoReel shutdown];
    [self.videoReel dismissViewControllerAnimated:NO completion:nil];
    self.videoReel = nil;
}

- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self animateOpenChannels:channel];
}

- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel atFrame:(Frame *)videoFrame
{
    [self animateCloseChannels:channel atFrame:videoFrame];
}


#pragma mark - ShelbyHome Private methods
- (void)animateOpenChannels:(DisplayChannel *)channel 
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }
    
    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForOpeningChannel:channel];
    
    CGFloat topBarHeight = self.topBar.frame.size.height;
    animationViews.topView.frame = CGRectMake(animationViews.topView.frame.origin.x, animationViews.topView.frame.origin.y + topBarHeight, animationViews.topView.frame.size.width, animationViews.topView.frame.size.height);
    animationViews.centerView.frame = CGRectMake(animationViews.centerView.frame.origin.x, animationViews.centerView.frame.origin.y + topBarHeight, animationViews.centerView.frame.size.width, animationViews.centerView.frame.size.height);
    animationViews.bottomView.frame = CGRectMake(animationViews.bottomView.frame.origin.x, animationViews.bottomView.frame.origin.y + topBarHeight, animationViews.bottomView.frame.size.width, animationViews.bottomView.frame.size.height);
    
    
    [self.videoReel.view addSubview:animationViews.centerView];
    [self.videoReel.view addSubview:animationViews.bottomView];
    [self.videoReel.view addSubview:animationViews.topView];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarStyleBlackTranslucent];
    
    [self presentViewController:self.videoReel animated:NO completion:^{
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [animationViews.centerView setFrame:animationViews.finalCenterFrame];
            [animationViews.centerView setAlpha:0];
            [animationViews.topView setFrame:animationViews.finalTopFrame];
            [animationViews.bottomView setFrame:animationViews.finalBottomFrame];
        } completion:^(BOOL finished) {
            [animationViews.centerView removeFromSuperview];
            [animationViews.bottomView removeFromSuperview];
            [animationViews.topView removeFromSuperview];
            
            // KP KP: TODO: send a message to brain that it can start accepting new events
            [self setAnimationInProgress:NO];
        }];
    }];
}

- (void)animateCloseChannels:(DisplayChannel *)channel atFrame:(Frame *)frame
{
    if (self.animationInProgress) {
        return;
    } else {
        [self setAnimationInProgress:YES];
    }

    [self.browseVC highlightFrame:frame atChannel:channel];
    
    ShelbyHideBrowseAnimationViews *animationViews = [self.browseVC animationViewForClosingChannel:channel];
 
    [self.videoReel.view addSubview:animationViews.centerView];
    [self.videoReel.view addSubview:animationViews.bottomView];
    [self.videoReel.view addSubview:animationViews.topView];
    
    [self.videoReel.view bringSubviewToFront:animationViews.centerView];
    [self.videoReel.view bringSubviewToFront:animationViews.bottomView];
    [self.videoReel.view bringSubviewToFront:animationViews.topView];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarStyleBlackTranslucent];
    [animationViews.centerView setAlpha:0];
    
    CGFloat topBarHeight = self.topBar.frame.size.height;
    CGRect finalTopFrame = CGRectMake(animationViews.finalTopFrame.origin.x, animationViews.finalTopFrame.origin.y + topBarHeight, animationViews.finalTopFrame.size.width, animationViews.finalTopFrame.size.height);
    CGRect finalCenterFrame = CGRectMake(animationViews.finalCenterFrame.origin.x, animationViews.finalCenterFrame.origin.y + topBarHeight, animationViews.finalCenterFrame.size.width, animationViews.finalCenterFrame.size.height);
    CGRect finalBottomFrame = CGRectMake(animationViews.finalBottomFrame.origin.x, animationViews.finalBottomFrame.origin.y + topBarHeight, animationViews.finalBottomFrame.size.width, animationViews.finalBottomFrame.size.height);
    
    [self.topBar setAlpha:0];
    [self.videoReel hideOverlayView];
    [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        [animationViews.centerView setFrame:finalCenterFrame];
        [animationViews.centerView setAlpha:1];
        [animationViews.topView setFrame:finalTopFrame];
        [animationViews.bottomView setFrame:finalBottomFrame];
    } completion:^(BOOL finished) {
        [self.videoReel dismissViewControllerAnimated:NO completion:^{
            [UIView animateWithDuration:0.5 animations:^{
                [self.topBar setAlpha:1];
            }];
            [self.videoReel shutdown];
            self.videoReel = nil;
        }];
        [self setAnimationInProgress:NO];
    }];
}

- (void)initializeVideoReelWithChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    _videoReel = [[SPVideoReel alloc] initWithChannel:channel
                                     andVideoEntities:[self deduplicatedEntriesForChannel:channel]
                                              atIndex:index];
    self.videoReel.delegate = self.masterDelegate;
}

#pragma mark - Authorization Methods (Private)
- (void)dismissAuthorizationVC
{
    if (self.authorizationVC) {
        [self.authorizationVC dismissViewControllerAnimated:NO completion:nil];
        self.authorizationVC = nil;
    }
}

- (void)login
{
    NSString *authorizationVCNibName = nil;
    if (DEVICE_IPAD) {
        authorizationVCNibName = @"AuthorizationView";
    } else {
        authorizationVCNibName = @"AuthorizationView-iPhone";
    }
    _authorizationVC = [[AuthorizationViewController alloc] initWithNibName:authorizationVCNibName bundle:nil];
    
    CGFloat xOrigin = self.view.frame.size.width / 2.0f - self.authorizationVC.view.frame.size.width / 4.0f;
    CGFloat yOrigin = self.view.frame.size.height / 5.0f - self.authorizationVC.view.frame.size.height / 4.0f;
    CGSize loginDialogSize = self.authorizationVC.view.frame.size;
    
    [self.authorizationVC setModalInPopover:YES];
    [self.authorizationVC setModalPresentationStyle:UIModalPresentationFormSheet];
    [self.authorizationVC setDelegate:self];
    
    [self presentViewController:self.authorizationVC animated:YES completion:nil];
    
    self.authorizationVC.view.superview.frame = CGRectMake(xOrigin, yOrigin, loginDialogSize.width, loginDialogSize.height);
}

- (void)logout
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Logout?"
                                                        message:@"Are you sure you want to logout?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Logout", nil];
 	
    [alertView show];
}

#pragma mark - UIPopoverControllerDelegate methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.settingsPopover = nil;
}

#pragma mark - UIAlertViewDelegate Methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self logoutUser];
    }
}
#pragma mark - SettingsViewDelegate methods
- (void)dismissPopover
{
    // Popover is only for the iPad
    if (DEVICE_IPAD) {
        if (self.settingsPopover && [self.settingsPopover isPopoverVisible]) {
            [self.settingsPopover dismissPopoverAnimated:NO];
            self.settingsPopover = nil;
        }
    }
}

- (void)logoutUser
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(logoutUser)]) {
        [self.masterDelegate logoutUser];
    }
    
    [self dismissPopover];
    [self setupSettingsView];
}

- (void)connectToFacebook
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(connectToFacebook)]) {
        [self.masterDelegate connectToFacebook];
    }
    
    [self dismissPopover];
}

- (void)connectToTwitter
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(connectToTwitter)]) {
        [self.masterDelegate connectToTwitter];
    }
    
    [self dismissPopover];
}

- (void)launchMyRoll
{
    [self dismissPopover];

    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(playMyRoll)]) {
        [self.masterDelegate playMyRoll];
    }
}

- (void)launchMyLikes
{
    [self dismissPopover];

    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(playMyLikes)]) {
        [self.masterDelegate playMyLikes];
    }
}

#pragma mark - AuthorizationDelegate
- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password
{
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(loginUserWithEmail:password:)]) {
        [self.masterDelegate loginUserWithEmail:email password:password];
    }
}

#pragma mark - Beta Stuff
- (IBAction)feedbackTapped:(UIButton *)sender {
    if([MFMailComposeViewController canSendMail]){
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        mailer.mailComposeDelegate = self;
        [mailer setSubject:[NSString stringWithFormat:@"iPad Feedback (%@-%@, %@ v%@)", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"], [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"], [[UIDevice currentDevice] model], [[UIDevice currentDevice] systemVersion]]];
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

#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self launchMyRoll];
    } else if (buttonIndex == 1) {
        [self launchMyLikes];
    } else if (buttonIndex == 2) {
        [self connectToFacebook];
    } else if (buttonIndex == 3) {
        [self connectToTwitter];
    } else if (buttonIndex == 4) {
        [self logout];
    }
}
@end
