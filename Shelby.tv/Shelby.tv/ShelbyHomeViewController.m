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
#import "Roll+Helper.h"
#import "SettingsViewController.h"
#import "ShelbyAlertView.h"
#import "ShelbyStreamBrowseViewController.h"
#import "SPVideoReel.h"
//#import "TriageViewController.h"
#import "User+Helper.h"

@interface ShelbyHomeViewController ()
@property (nonatomic, weak) IBOutlet UIView *topBar;
@property (nonatomic, weak) IBOutlet UILabel *topBarTitle;

@property (nonatomic, strong) UIView *settingsView;
@property (strong, nonatomic) UIPopoverController *settingsPopover;
@property (strong, nonatomic) AuthorizationViewController *authorizationVC;

@property (nonatomic, strong) BrowseViewController *browseVC;
@property (nonatomic, strong) NSMutableArray *streamBrowseVCs;
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
        //the actual view controllers are created in setChannels:
        _streamBrowseVCs = [@[] mutableCopy];
    }
    
    [self setupSettingsView];
    
    [self.view bringSubviewToFront:self.channelsLoadingActivityIndicator];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


- (NSUInteger)supportedInterfaceOrientations
{
    if (DEVICE_IPAD) {
        return UIInterfaceOrientationMaskLandscape;
    } else {
        return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape;
    }
}

-(BOOL) shouldAutorotate {
    return YES;
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

// We assume these are all of our channels, in the correct order
- (void)setChannels:(NSArray *)channels
{
    if (![channels isEqualToArray:_channels]) {
        //DLog(@"Replacing ALL Channels... %@ --becomes--> %@", _channels, channels);
        _channels = channels;
        if (DEVICE_IPAD) {
            self.browseVC.channels = channels;
            
        } else {
            //find or create new ShelbyStreamBrowseViewControllers for this array of channels
            NSMutableArray *newStreamBrowseVCs = [@[] mutableCopy];
            for (DisplayChannel *ch in channels) {
                ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:ch];
                if (!sbvc) {
                    sbvc = [[ShelbyStreamBrowseViewController alloc] initWithNibName:@"ShelbyStreamBrowseView" bundle:nil];
                    [sbvc setEntries:nil forChannel:ch];
                    sbvc.browseDelegate = self.masterDelegate;
                }
                [newStreamBrowseVCs addObject:sbvc];
            }
            
            //remove old VCs (some of which may get re-used)
            //NB: we expect new channel for focus to be set by an outsider
            for (ShelbyStreamBrowseViewController *sbvc in _streamBrowseVCs) {
                if (sbvc.view.superview) {
                    [sbvc.view removeFromSuperview];
                    [sbvc removeFromParentViewController];
                }
            }
            
            //add the new VCs with proper frame
            for (ShelbyStreamBrowseViewController *newSBVC in newStreamBrowseVCs) {
                [newSBVC.view setFrame:CGRectMake(0, 0, newSBVC.view.frame.size.width, newSBVC.view.frame.size.height)];
            }
            _streamBrowseVCs = newStreamBrowseVCs;
        }
    }
}

- (void)removeChannel:(DisplayChannel *)channel
{
    DLog(@"Removing channel %@", channel);
    
    NSMutableArray *lessChannels = [_channels mutableCopy];
    [lessChannels removeObject:channel];
    _channels = lessChannels;
    if (DEVICE_IPAD) {
        self.browseVC.channels = _channels;
    } else {
        ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
        if (sbvc) {
            if (sbvc.view.superview) {
                [sbvc.view removeFromSuperview];
                [sbvc removeFromParentViewController];
            }
            [_streamBrowseVCs removeObject:sbvc];
        }
    }
}

- (void)focusOnChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        //do nothing
    } else {
        //remove current focus
        for (ShelbyStreamBrowseViewController *sbvc in _streamBrowseVCs) {
            if (sbvc.view.superview) {
                [sbvc.view removeFromSuperview];
                [sbvc removeFromParentViewController];
            }
        }

        ShelbyStreamBrowseViewController *sbvc = [self streamBrowseViewControllerForChannel:channel];
        STVAssert(sbvc, @"should not be asked to focus on a channel we don't have");
        [sbvc willMoveToParentViewController:self];
        [self.view addSubview:sbvc.view];
        [self addChildViewController:sbvc];
        [sbvc didMoveToParentViewController:self];
        [self.view addSubview:self.topBar];
        [self.view bringSubviewToFront:self.topBar];
    }
}

- (void)focusOnEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        //When we implement new iPad interface, will probably want to update our persisten stream view here
    } else {
        [[self streamBrowseViewControllerForChannel:channel] focusOnEntity:entity inChannel:channel];
    }
}

- (void)setEntries:(NSArray *)channelEntries forChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        [self.browseVC setEntries:channelEntries forChannel:channel];
    } else {
        [[self streamBrowseViewControllerForChannel:channel] setEntries:channelEntries forChannel:channel];
    }
    [self setPlayerEntriesForChannel:channel];
}

- (ShelbyStreamBrowseViewController *)streamBrowseViewControllerForChannel:(DisplayChannel *)channel
{
    for (ShelbyStreamBrowseViewController *sbvc in _streamBrowseVCs) {
        if (sbvc.channel == channel) {
            return sbvc;
        }
    }
    return nil;
}

- (NSInteger)indexOfDisplayedEntry:(id)entry inChannel:(DisplayChannel *)channel
{
    NSArray *dedupdEntries = [self deduplicatedEntriesForChannel:channel];
    return [dedupdEntries indexOfObject:entry];
}

- (void)addEntries:(NSArray *)newChannelEntries toEnd:(BOOL)shouldAppend ofChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        [self.browseVC addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel];
    } else {
        [[self streamBrowseViewControllerForChannel:channel] addEntries:newChannelEntries toEnd:shouldAppend ofChannel:channel];
    }
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
    if (self.browseVC) {
        return [self.browseVC entriesForChannel:channel];
    } else {
        return [[self streamBrowseViewControllerForChannel:channel] entriesForChannel:channel];
    }
}

- (NSArray *)deduplicatedEntriesForChannel:(DisplayChannel *)channel
{
    if (DEVICE_IPAD) {
        return [self.browseVC deduplicatedEntriesForChannel:channel];
    } else {
        return [[self streamBrowseViewControllerForChannel:channel] deduplicatedEntriesForChannel:channel];
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
        for (ShelbyStreamBrowseViewController *sbvc in self.streamBrowseVCs) {
            sbvc.browseDelegate = masterDelegate;
        }
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
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 0, 60, 44)];
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
        _settingsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - 70, 0, 120, 44)];
        UIButton *login = [UIButton buttonWithType:UIButtonTypeCustom];
        [login setFrame:CGRectMake(7, 7, 60, 30)];
        [login setBackgroundImage:[UIImage imageNamed:@"login.png"] forState:UIControlStateNormal];
        [login setTitle:@"Login" forState:UIControlStateNormal];
        [[login titleLabel] setFont:[UIFont fontWithName:@"HelveticaNeue-Bold" size:14]];
        [[login titleLabel] setTextColor:[UIColor whiteColor]];
        [login addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [self.settingsView addSubview:login];
    }
    
    [self.topBar addSubview:self.settingsView];
    [self.settingsView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [self.view bringSubviewToFront:self.topBar];
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
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Stream", @"My Shares", @"My Likes", @"Connect to Facebook", @"Connect to Twitter", @"Logout", nil];
        actionSheet.destructiveButtonIndex = 5;
        [actionSheet showInView:self.view];
    }
}


- (void)playChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self initializeVideoReelWithChannel:channel atIndex:index];

    if (DEVICE_IPAD) {
        //TODO
        DLog(@"TODO: handle play channel for iPad");
    } else {
        [self.videoReel willMoveToParentViewController:self];
        [self addChildViewController:self.videoReel];
        [self.view insertSubview:self.videoReel.view atIndex:0];
        [self.videoReel didMoveToParentViewController:self];
        
        [self streamBrowseViewControllerForChannel:self.videoReel.channel].viewMode = ShelbyStreamBrowseViewForPlayback;
    }
}

- (void)dismissPlayer
{
    [self streamBrowseViewControllerForChannel:self.videoReel.channel].viewMode = ShelbyStreamBrowseViewDefault;
    
    [self.videoReel shutdown];
    [self.videoReel.view removeFromSuperview];
    [self.videoReel removeFromParentViewController];
    self.videoReel = nil;
}

//DEPRECATED
- (void)animateLaunchPlayerForChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    [self initializeVideoReelWithChannel:channel atIndex:index];
    [self animateOpenChannels:channel];
}

//DEPRECATED
- (void)animateDismissPlayerForChannel:(DisplayChannel *)channel atFrame:(Frame *)videoFrame
{
    [self animateCloseChannels:channel atFrame:videoFrame];
}


#pragma mark - ShelbyHome Private methods

//DEPRECATED
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

//DEPRECATED
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

    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToMyRoll)]) {
        [self.masterDelegate goToMyRoll];
    }
}

- (void)launchMyLikes
{
    [self dismissPopover];

    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToMyLikes)]) {
        [self.masterDelegate goToMyLikes];
    }
}

- (void)launchMyStream
{
    [self dismissPopover];
    
    if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToMyStream)]) {
        [self.masterDelegate goToMyStream];
    }
}

- (IBAction)dvrButtonTapped:(UIButton *)sender {
    //super hacky, fine for now
    if ([sender.titleLabel.text isEqualToString:@"DVR"]) {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToDVR)]) {
            [self.masterDelegate goToDVR];
            [sender setTitle:@"Back" forState:UIControlStateNormal];
        }
    } else {
        if ([self.masterDelegate conformsToProtocol:@protocol(ShelbyHomeDelegate)] && [self.masterDelegate respondsToSelector:@selector(goToDefaultChannel)]) {
            [self.masterDelegate goToDefaultChannel];
            [sender setTitle:@"DVR" forState:UIControlStateNormal];
        }
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
        [self launchMyStream];
    } else if (buttonIndex == 1) {
        [self launchMyRoll];
    } else if (buttonIndex == 2) {
        [self launchMyLikes];
    } else if (buttonIndex == 3) {
        [self connectToFacebook];
    } else if (buttonIndex == 4) {
        [self connectToTwitter];
    } else if (buttonIndex == 5) {
        [self logout];
    }
}
@end
