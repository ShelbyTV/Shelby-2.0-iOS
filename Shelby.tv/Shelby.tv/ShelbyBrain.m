//
//  ShelbyBrain.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/1/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrain.h"
#import "Dashboard+Helper.h"
#import "DashboardEntry.h"
#import "DisplayChannel+Helper.h"
#import "ShelbyDVRController.h"
#import "SettingsViewController.h"
#import "ShelbyModelArrayUtility.h"
#import "Roll+Helper.h"
#import "ShelbyModel.h"
#import "SPVideoExtractor.h"
#import "ShelbyAlert.h"
#import "User+Helper.h"

#define kShelbyChannelsStaleTime -600 //10 minutes
#define kShelbyTutorialMode @"kShelbyTutorialMode"

NSString * const kShelbyDVRDisplayChannelID = @"dvrDisplayChannel";
NSString * const kShelbyCommunityChannelID = @"521264b4b415cc44c9000001";

NSString *const kShelbyLastActiveDate = @"kShelbyLastActiveDate";

@interface ShelbyBrain()

//our two primary view controllers
@property (strong, nonatomic) WelcomeViewController *welcomeVC;
@property (strong, nonatomic) ShelbyHomeViewController *homeVC;

//login and signup view controllers
@property (strong, nonatomic) LoginViewController *loginVC;
@property (strong, nonatomic) SignupFlowNavigationViewController *signupFlowVC;

@property (nonatomic, strong) NSDate *channelsLoadedAt;
@property (nonatomic, strong) DisplayChannel *currentChannel;

@property (nonatomic, strong) NSMutableArray *cachedFetchedChannels;
@property (nonatomic, strong) NSMutableArray *remoteFetchedChannels;
@property (nonatomic, strong) DisplayChannel *dvrChannel;
@property (nonatomic, strong) DisplayChannel *offlineLikesChannel;

@property (nonatomic, strong) ShelbyDVRController *dvrController;

@property (nonatomic, strong) NSDictionary *postFetchInvocationForChannel;

@property (nonatomic, strong) ShelbyAlert *currentAlertView;
@end

@implementation ShelbyBrain

- (void)handleDidBecomeActive
{
    NSDate *lastActiveDate = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyLastActiveDate];
    if (lastActiveDate && [lastActiveDate isKindOfClass:[NSDate class]] && [lastActiveDate timeIntervalSinceNow] < kShelbyChannelsStaleTime) {
        [self.homeVC dismissVideoReel];
    }
    [User sessionDidBecomeActive];
    [self.homeVC handleDidBecomeActive];

    //see method comments for explanation
    [self refreshUsersStreamAfterDelay];
}

- (void)handleWillResignActive
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyLastActiveDate];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.homeVC handleWillResignActive];
    [User sessionDidPause];
}

- (void)handleDidFinishLaunching
{
    [ShelbyDataMediator sharedInstance].delegate = self;
    
    if (![WelcomeViewController isWelcomeComplete]) {
        [self activateWelcomeViewController];
    } else {
        [self activateHomeViewController];
        User *currentUser = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
        if (currentUser) {
            [self fetchUserChannelsForceSwitchToUsersStream:YES];
        } else {
            [[ShelbyDataMediator sharedInstance] fetchAllUnsyncedLikes];
        }
    }
    [self.mainWindow makeKeyAndVisible];
}

- (void)activateWelcomeViewController
{
    UIStoryboard *welcomeStoryboard = [UIStoryboard storyboardWithName:@"Welcome" bundle:nil];
    self.welcomeVC = [welcomeStoryboard instantiateInitialViewController];
    self.welcomeVC.delegate = self;
    self.mainWindow.rootViewController = self.welcomeVC;
}

- (void)activateHomeViewController
{
    if (self.homeVC) {
        return;
    }
    
    NSString *rootViewControllerNibName = nil;
//    if (DEVICE_IPAD) {
//        rootViewControllerNibName = @"ShelbyHomeView";
//    } else {
    rootViewControllerNibName = @"ShelbyHomeView-iPhone";
//    }
    self.homeVC = [[ShelbyHomeViewController alloc] initWithNibName:rootViewControllerNibName bundle:nil];
    self.mainWindow.rootViewController = self.homeVC;
    self.welcomeVC = nil;

    User *currentUser = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    self.homeVC.currentUser = currentUser;
    self.homeVC.masterDelegate = self;

    [self setupDVR];

    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] < kShelbyChannelsStaleTime){
        [[ShelbyDataMediator sharedInstance] fetchGlobalChannels];
    }
}

- (void)setupDVR
{
    self.dvrChannel = [DisplayChannel channelForTransientEntriesWithID:kShelbyDVRDisplayChannelID
                                                                 title:@"DVR"
                                                             inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    self.dvrController = [[ShelbyDVRController alloc] init];
}

- (void)presentLoginVC
{
    UIStoryboard *loginStoryboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UINavigationController *loginNav = [loginStoryboard instantiateInitialViewController];
    self.loginVC = loginNav.viewControllers[0];
    self.loginVC.delegate = self;

    [self.mainWindow.rootViewController presentViewController:loginNav animated:YES completion:nil];
}

- (void)dismissLoginVCCompletion:(void (^)(void))completion
{
    [self.mainWindow.rootViewController dismissViewControllerAnimated:YES completion:^{
        self.loginVC = nil;
        if (completion) {
            completion();
        }
    }];
}

- (void)presentSignupVC
{
    UIStoryboard *signupFlowStoryboard = [UIStoryboard storyboardWithName:@"SignupFlow" bundle:nil];
    self.signupFlowVC = (SignupFlowNavigationViewController *)[signupFlowStoryboard instantiateInitialViewController];
    self.signupFlowVC.signupDelegate = self;

    [self.mainWindow.rootViewController presentViewController:self.signupFlowVC animated:YES completion:nil];
}

- (void)dismissSigupVCCompletion:(void (^)(void))completion
{
    [self.mainWindow.rootViewController dismissViewControllerAnimated:YES completion:^{
        self.signupFlowVC = nil;
        if (completion) {
            completion();
        }
    }];
}

- (void)handleLocalNotificationReceived:(UILocalNotification *)notification
{
    [self goToDVR];
}

- (void)fetchUserChannelsForceSwitchToUsersStream:(BOOL)forceUsersStream
{
    NSArray *allChannels = [self constructAllChannelsArray];
    self.homeVC.channels = allChannels;
    if (!self.currentChannel || forceUsersStream) {
        [self goToUsersStream];
    }

    NSArray *userChannels = [User channelsForUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    for (DisplayChannel *channel in userChannels) {
        [self populateChannel:channel withActivityIndicator:YES];
    }
}

// The backend is dynamically adding "old recommendations" into a user's stream, triggered by a fetch.
// So that these will be seen by the user (without them having to manually refresh), we refresh the stream after a delay.
// If a rec comes in (ie. a few frames older than the newest one on the user's dashboard) it will be
// inserted at the correct location by our views.
//
// Canonical use case: app becomes active (is lauched, and all channels are fetched like normal),
// a rec has been (is) generated on backend, we refresh stream behind the scenes, users scrolls, user sees rec.
- (void)refreshUsersStreamAfterDelay
{
    if ([self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO]) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kShelbyStreamRefreshForRecommendationsDelay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            User *user = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
            if (user) {
                DisplayChannel *usersStreamChannel = [[ShelbyDataMediator sharedInstance] fetchDisplayChannelOnMainThreadContextForDashboardID:user.userID];
                [self populateChannel:usersStreamChannel withActivityIndicator:NO];
            }
        });
    }
}

- (void)populateChannels:(NSArray *)channelsToPopulate
{
    for (DisplayChannel *channel in channelsToPopulate){
        [self populateChannel:channel withActivityIndicator:YES];
    }
}

// we expect to hear an answer via fetchEntriesDidCompleteForChannel:with:fromCache: on main thread
- (void)populateChannel:(DisplayChannel *)channel withActivityIndicator:(BOOL)showSpinner
{
    if (channel == self.dvrChannel) {
        //TODO: this should go through DataMediator (like offline likes, below)
        NSArray *dvrEntries = [self.dvrController currentDVREntriesOrderedLIFO:YES
                                                                     inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
        NSMutableArray *dvrFrames = [[NSMutableArray alloc] initWithCapacity:[dvrEntries count]];
        for (DVREntry *dvrEntry in dvrEntries) {
            [dvrFrames addObject:[dvrEntry childFrame]];
        }
        [self fetchEntriesDidCompleteForChannel:channel with:dvrFrames fromCache:YES];
        
    } else if (channel == self.offlineLikesChannel) {
        [[ShelbyDataMediator sharedInstance] fetchAllUnsyncedLikes];

    } else {
        //normal channels
        if(showSpinner){
            [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:YES];
        }
        
        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel sinceEntry:nil];
        
    }
}

- (User *)fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:(BOOL)forceRefresh
{
     return [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:forceRefresh];
}

#pragma mark - ShelbyDataMediatorDelegate
- (void)loginUserDidCompleteWithError:(NSString *)errorMessage
{
    [self.loginVC loginFailed:errorMessage];
}

- (void)loginUserDidComplete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self userWasUpdated];
        [User sessionDidBecomeActive];
        [self dismissLoginVCCompletion:^{
            [self activateHomeViewController];
            [self fetchUserChannelsForceSwitchToUsersStream:YES];
        }];
    });
}

- (void)userWasUpdated
{
    [self setCurrentUser:[self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:YES]];
}

#pragma mark - SignupFlowNavigationViewDelegate
- (void)facebookConnectDidComplete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setCurrentUser:[self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:YES]];
    });
}

- (void)facebookConnectDidCompleteWithError:(NSString *)errorMessage
{
    if (errorMessage){
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                                message:errorMessage 
                                                               delegate:nil 
                                                      cancelButtonTitle:@"OK" 
                                                      otherButtonTitles:nil];
            [alertView show];
        });
    }
}

- (void)twitterConnectDidComplete
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setCurrentUser:[self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:YES]];
    });
}

- (void)twitterConnectDidCompleteWithError:(NSString *)errorMessage
{
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                            message:errorMessage 
                                                           delegate:nil 
                                                  cancelButtonTitle:@"OK" 
                                                  otherButtonTitles:nil];
        [alertView show];
    });
}

-(void)fetchGlobalChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached
{
    //channels could come from CoreData, but right now come from API only

    if (cached) {
        self.cachedFetchedChannels = [channels mutableCopy];
    } else {
        self.remoteFetchedChannels = [channels mutableCopy];
    }
    NSArray *curChannels = self.homeVC.channels;

    if(!curChannels || ![channels isEqualToArray:curChannels]){
        //new or different channels...  update!
        self.homeVC.channels = [self constructAllChannelsArray];
        if (!self.currentChannel && [self communityChannel]) {
            [self goToCommunityChannel];
        }
    }

    if(cached){
        //could populate channels w/ cached data only here, and then API request data in else block
    } else {
        [self.homeVC.channelsLoadingActivityIndicator stopAnimating];
        [self populateChannels:channels];
        self.channelsLoadedAt = [NSDate date];
    }
}

-(void)fetchGlobalChannelsDidCompleteWithError:(NSError *)error
{
    [self showErrorView:error];
    DLog(@"TODO: handle fetch channels did complete with error %@", error);
}

//channelEntries filled with ShelbyModel (specifically, a DashboardEntry or Frame)
-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                    with:(NSArray *)channelEntries
                               fromCache:(BOOL)cached
{
    STVDebugAssert([NSThread isMainThread], @"expecting to be called on main thread");
    
    //the choke point where unplayable videos may not pass
    NSPredicate *onlyPlayableVideos = [NSPredicate predicateWithBlock:^BOOL(id entry, NSDictionary *bindings) {
        return [entry isPlayable];
    }];
    channelEntries = [channelEntries filteredArrayUsingPredicate:onlyPlayableVideos];
    
    NSArray *curEntries = [self.homeVC entriesForChannel:channel];
    if(curEntries && [curEntries count] && [channelEntries count]){
        ShelbyModelArrayUtility *mergeUtil = [ShelbyModelArrayUtility determineHowToMergePossiblyNew:channelEntries intoExisting:curEntries];
        if([mergeUtil.actuallyNewEntities count]){
            [self.homeVC addEntries:mergeUtil.actuallyNewEntities toEnd:mergeUtil.actuallyNewEntitiesShouldBeAppended ofChannel:channel];
            if(!mergeUtil.actuallyNewEntitiesShouldBeAppended){
                [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:mergeUtil.actuallyNewEntities[0]];
            }
        } else {
            //full subset, nothing to add
        }
    } else {
        // Don't update entries if we have zero entries in cache
        if ([channelEntries count] != 0 || !cached) {
            [self.homeVC setEntries:channelEntries forChannel:channel];
        }

        if ([channelEntries count]) {
            [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:channelEntries[0]];
        }
    }
    
    if(!cached){
        [self.homeVC fetchDidCompleteForChannel:channel];
        [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
        [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:NO];
    }
    
    if (self.postFetchInvocationForChannel && [channel objectID] && self.postFetchInvocationForChannel[channel.objectID]) {
        [self.postFetchInvocationForChannel[channel.objectID] invoke];
    }
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
    [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:NO];
    
    [self showErrorView:error];
}

-(void)fetchOfflineLikesDidCompleteForChannel:(DisplayChannel *)channel
                                         with:(NSArray *)channelEntries
{
    self.offlineLikesChannel = channel;
    if (self.homeVC && ![self.homeVC.channels containsObject:self.offlineLikesChannel]) {
        //update homeVC with this additional channel
        self.homeVC.channels = [self constructAllChannelsArray];
    }
    STVAssert(self.offlineLikesChannel == channel, @"we have multiple offline likes channels, not good");

    [self.homeVC setEntries:channelEntries forChannel:channel];
    
    [self.homeVC refreshActivityIndicatorForChannel:channel shouldAnimate:NO];
    [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:NO];
}

- (void)removeFrame:(Frame *)frame fromChannel:(DisplayChannel *)channel
{
    NSArray *channelEntries = [self.homeVC entriesForChannel:channel];
    STVAssert(channelEntries && [channelEntries[0] isKindOfClass:[Frame class]], @"can't remove frame from channel that doesn't have frames");
    NSMutableArray *newChannelEntries = [channelEntries mutableCopy];
    [newChannelEntries removeObject:frame];
    [self.homeVC setEntries:newChannelEntries forChannel:channel];
}

// 100% of the logic of channel ordering.
// HomeVC just takes the array it's given, assuming it's in the correct order.
- (NSMutableArray *)constructAllChannelsArray
{
    NSMutableArray *allChannels = [@[] mutableCopy];

    // add user channels (if there is no user, nothing is added)
    NSArray *userChannels = [User channelsForUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    [allChannels addObjectsFromArray:userChannels];

    if (self.offlineLikesChannel) {
        [allChannels addObject:self.offlineLikesChannel];
    }

    if (self.remoteFetchedChannels) {
        for (id ch in self.remoteFetchedChannels) {
            if (![allChannels containsObject:ch]) {
                [allChannels addObject:ch];
            }
        }
    }

    if (self.cachedFetchedChannels) {
        for (id ch in self.cachedFetchedChannels) {
            if (![allChannels containsObject:ch]) {
                [allChannels addObject:ch];
            }
        }
    }

    return allChannels;
}

- (DisplayChannel *)communityChannel
{
    DisplayChannel *communityCh = [DisplayChannel fetchChannelWithDashboardID:kShelbyCommunityChannelID
                                                                    inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    return communityCh;
}

#pragma mark - Helper Methods
- (NSInteger)nextChannelForDirection:(BOOL)up
{
    NSArray *channels = self.homeVC.channels;
    NSUInteger numberOfChannels = [channels count];
    // KP KP: TODO: deal with the case that the channel not found
    NSInteger currentChannelIndex = [channels indexOfObject:self.currentChannel];
    NSInteger next = up ? -1 : 1;
    NSInteger nextChannel = currentChannelIndex + next;
    if (nextChannel < 0) {
        nextChannel = numberOfChannels + nextChannel;
    } else if ((unsigned)nextChannel == numberOfChannels) {
        nextChannel = 0;
    }
    
    return nextChannel;
}

//returns YES if we launched the channel
//only launches the channel if it has content and the index into that content is valid
- (BOOL)launchChannel:(DisplayChannel *)channel atIndex:(NSInteger)index
{
    self.currentChannel = channel;

    if([channel hasEntityAtIndex:index]){
        [self.homeVC playChannel:channel atIndex:index];
        return YES;
    } else {
        return NO;
    }
}

- (void)showErrorView:(NSError *)error
{
    NSString *errorMessage = nil;
    if (error && (error.code == 1009 || error.code == 1001)) {
        errorMessage = @"Please make sure you are connected to the Internet.";
    } else {
        errorMessage = @"Could not connect. Please try again later.";
    }
    
    ShelbyAlert *alertView = [[ShelbyAlert alloc] initWithTitle:@"Error" message:errorMessage dismissButtonTitle:@"OK" autodimissTime:8 onDismiss:nil];
    [alertView show];
}

#pragma mark - ShelbyStreamBrowseManagementDelegate Methods

// Method below is delegate method of the SPVideoReelProtocol & ShelbyBrowseProtocol
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    if (channel != self.dvrChannel) {
        //OPTIMIZE: could be smarter, don't ALWAYS send this fetch if we have an outstanding fetch
        [self.homeVC loadMoreActivityIndicatorForChannel:channel shouldAnimate:YES];
        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel sinceEntry:entry];
    }
}

// If returns nil there is no NoContentView to show for DisplayChannel. If there is one, return it's name.
- (NSString *)nameForNoContentViewForDisplayChannel:(DisplayChannel *)channel
{
    
    BOOL likesChannel = NO;
    BOOL sharesChannel = NO;
    User *user = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    if (user) {
        if ([user.likesRollID isEqualToString:channel.roll.rollID]) {
            likesChannel = YES;
        } else if ([user.publicRollID isEqualToString:channel.roll.rollID]) {
            sharesChannel = YES;
        }
    } else if (self.offlineLikesChannel == channel) {
        likesChannel = YES;
    }
    
    // TODO: add MyStream for NoSharesView - in case user has nothing in their roll and they switch to their shares.
    
    if (likesChannel) {
        return @"NoLikesView";
    } else if (sharesChannel) {
        return @"NoSharesView";
    } else {
        return nil;
    }
}


#pragma mark - SPVideoReelProtocol Methods
- (void)userDidSwitchChannelForDirectionUp:(BOOL)up
{
    [self.homeVC dismissVideoReel];
    NSInteger nextChannel = [self nextChannelForDirection:up];
    BOOL didChangeChannels = [self launchChannel:self.homeVC.channels[nextChannel] atIndex:0];
    if(!didChangeChannels){
        [self userDidSwitchChannelForDirectionUp:up];
    }
    
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryBrowse withAction:kAnalyticsBrowseActionLaunchPlaylistVerticalSwipe withLabel:nil];
}

- (void)userDidCloseChannelAtFrame:(Frame *)frame
{
    //we used to do this with an old animated dismiss... no longer
    [self.homeVC dismissVideoReel];
    
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryBrowse withAction:kAnalyticsBrowseActionClosePlayerByPinch withLabel:nil];

}

//DEPRECATED
- (DisplayChannel *)displayChannelForDirection:(BOOL)up
{
//    if (self.currentPlayerTutorialMode != SPTutorialModeNone) {
//        self.currentPlayerTutorialMode = SPTutorialModePinch;
//    }
//
//    NSUInteger nextChannel = [self nextChannelForDirection:up];
//    
//    if (nextChannel < [self.userChannels count]) {
//        return self.userChannels[nextChannel];
//    } else {
//        return self.fetchedChannels[nextChannel - [self.userChannels count]];
//    }
    STVAssert(NO, @"DEPRECATED");
    return nil;
}

- (void)videoDidAutoadvance
{
    [self.homeVC videoDidAutoadvance];
}

- (void)didChangePlaybackToEntity:(id<ShelbyVideoContainer>)entity inChannel:(DisplayChannel *)channel
{
    [self.homeVC focusOnEntity:entity inChannel:channel];
}

- (BOOL)canRoll
{
    return self.homeVC.currentUser != nil;
}

- (void)userAskForFacebookPublishPermissions
{
    [[ShelbyDataMediator sharedInstance] userAskForFacebookPublishPermissions];
}

- (void)userAskForTwitterPublishPermissions
{
    [self connectToTwitter];
}

#pragma mark - Helpers

- (void)setCurrentUser:(User *)user
{
    [self.homeVC setCurrentUser:user];
    
    if (user) {
        [[ShelbyDataMediator sharedInstance] syncLikes];
    }
}

#pragma mark - SignupFlowNavigationViewDelegate

- (void)createUserWithName:(NSString *)name
                  andEmail:(NSString *)email
{
    [[ShelbyDataMediator sharedInstance] createUserWithName:name andEmail:email];
}

- (void)updateSignupUserWithName:(NSString *)name
                           email:(NSString *)email
{
    [[ShelbyDataMediator sharedInstance] updateUserWithName:name nickname:nil password:nil email:email avatar:nil rolls:nil completion:nil];
}

- (void)completeSignupUserWithName:(NSString *)name
                          username:(NSString *)username
                          password:(NSString *)password
                             email:(NSString *)email
                            avatar:(UIImage *)avatar
                          andRolls:(NSArray *)rolls
{
    [[ShelbyDataMediator sharedInstance] updateUserWithName:name
                                                   nickname:username
                                                   password:password
                                                      email:email
                                                     avatar:avatar
                                                      rolls:rolls
                                                 completion:^(NSError *error) {
                                                     [self dismissSigupVCCompletion:^{
                                                         //if we came from welcomeVC, switch over to homeVC (call is idempotent)
                                                         [self activateHomeViewController];
                                                         //make sure we're showing updated stream (whether we came from welcome or home)
                                                         [self fetchUserChannelsForceSwitchToUsersStream:YES];
                                                     }];
                                                 }];
}

- (void)signupFlowNavigationViewControllerWantsLogin:(SignupFlowNavigationViewController *)signupVC
{
    [self dismissSigupVCCompletion:^{
        [self presentLoginVC];
    }];
}

// Some of these methods are also for SettingsViewDelefate
#pragma mark - ShelbyHomeDelegate
- (void)presentUserLogin
{
    [self presentLoginVC];
}

- (void)presentUserSignup
{
    [self presentSignupVC];
}

- (void)logoutUser
{
    [User sessionDidPause];
    [[ShelbyDataMediator sharedInstance] logoutCurrentUser];
    self.currentUser = nil;

    [self goToCommunityChannel];
}

- (void)connectToFacebook
{
    [[ShelbyDataMediator sharedInstance] openFacebookSessionWithAllowLoginUI:YES];
}

- (void)inviteFacebookFriendsWasTapped
{
    [[ShelbyDataMediator sharedInstance] inviteFacebookFriends];
}

- (void)connectToTwitter
{
    //get topmost visible view
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while ([topViewController presentedViewController]) {
        topViewController = [topViewController presentedViewController];
    }

    [[ShelbyDataMediator sharedInstance] connectTwitterWithViewController:topViewController];
}

- (void)goToRollForID:(NSString *)rollID
{
    STVAssert(rollID, @"expects valid rollID");
    DisplayChannel *rollChannel = [[ShelbyDataMediator sharedInstance] fetchDisplayChannelOnMainThreadContextForRollID:rollID];
    [rollChannel deepRefreshMergeChanges:NO];
    [self goToDisplayChannel:rollChannel];
}

- (void)goToDashboardForId:(NSString *)dashboardID
{
    STVAssert(dashboardID, @"expects valid dashboardID");
    DisplayChannel *dashboardChannel = [[ShelbyDataMediator sharedInstance] fetchDisplayChannelOnMainThreadContextForDashboardID:dashboardID];
    [dashboardChannel deepRefreshMergeChanges:NO];
    [self goToDisplayChannel:dashboardChannel];
}

//on iPad, starts playing roll
//on iPhone, changes view
- (void)goToDisplayChannel:(DisplayChannel *)displayChannel
{
    if (displayChannel) {
//        if (DEVICE_IPAD && [displayChannel hasEntityAtIndex:0]) {
//            self.currentChannel = displayChannel;
//            [self.homeVC animateLaunchPlayerForChannel:displayChannel atIndex:0];
//            return;
//        } else {
        self.currentChannel = displayChannel;
        [self.homeVC focusOnChannel:displayChannel];
        return;
//        }
    }
    
    //fell through, can't go to the channel...
    NSString *message = nil;
    if (displayChannel && displayChannel.displayTitle) {
        message = [NSString stringWithFormat:@"We'd love to play %@, but it does not have any videos yet!", displayChannel.displayTitle];
    } else {
        message = @"Problem loading channel.";
    }
    self.currentAlertView =  [[ShelbyAlert alloc] initWithTitle:@"Error" message:message dismissButtonTitle:@"OK" autodimissTime:3.0 onDismiss:nil];
    [self.currentAlertView show];
}

- (void)goToUsersLikes
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    if (user) {
        [self goToRollForID:user.likesRollID];
    } else {
        [self populateChannel:self.offlineLikesChannel withActivityIndicator:NO];
        [self goToDisplayChannel:self.offlineLikesChannel];
    }
    [self.homeVC didNavigateToUsersLikes];
}

- (void)goToUsersRoll
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    [self goToRollForID:user.publicRollID];
    [self.homeVC didNavigateToUsersRoll];
}

- (void)goToUsersStream
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    [self goToDashboardForId:user.userID];
    [self.homeVC didNavigateToUsersStream];
}

- (void)goToDVR
{
    [self populateChannel:self.dvrChannel withActivityIndicator:NO];
    [self goToDisplayChannel:self.dvrChannel];
}

- (void)goToCommunityChannel
{
    [self goToDisplayChannel:[self communityChannel]];
    [self.homeVC didNavigateToCommunityChannel];
}

#pragma mark - UIActionSheetDelegate methods
//XXX Temporary until we show a proper settings view per Wireframes
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self connectToFacebook];
    } else if (buttonIndex == 1) {
        [self connectToTwitter];
    } else if (buttonIndex == 2) {
        [self logoutUser];
    }
}

#pragma mark - Tutorial Mode
- (NSDate *)tutorialCompleted
{
    NSDate *tutoraialCompletedOn = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyTutorialMode];
    return tutoraialCompletedOn;
}

- (void)setTutorialCompleted
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyTutorialMode];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

# pragma mark - WelcomeDelegate

- (void)welcomeDidTapSignup:(WelcomeViewController *)welcomeVC
{
    [self presentSignupVC];
}

- (void)welcomeDidTapLogin:(WelcomeViewController *)welcomeVC
{
    [self presentLoginVC];
}

- (void)welcomeDidTapPreview:(WelcomeViewController *)welcomeVC
{
    [self activateHomeViewController];
}

#pragma mark - LoginViewControllerDelegate

- (void)loginViewController:(LoginViewController *)loginVC loginWithUsername:(NSString *)usernameOrEmail password:(NSString *)password
{
    [[ShelbyDataMediator sharedInstance] loginUserWithEmail:usernameOrEmail password:password];
}

- (void)loginViewControllerDidCancel:(LoginViewController *)loginVC
{
    [self dismissLoginVCCompletion:nil];
}

- (void)loginViewControllerWantsSignup:(LoginViewController *)loginVC
{
    [self dismissLoginVCCompletion:^{
        [self presentSignupVC];
    }];
}

//mirror method signupFlowNavigationViewControllerWantsLogin: implemented above

@end
