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
#import "DashboardEntry+Helper.h"
#import "DisplayChannel+Helper.h"
#import "ShelbyDVRController.h"
#import "ShelbyErrorUtility.h"
#import "SettingsViewController.h"
#import "ShelbyModelArrayUtility.h"
#import "Roll+Helper.h"
#import "ShelbyABTestManager.h"
#import "ShelbyModel.h"
#import "ShelbyNotificationManager.h"
#import "ShelbyUserProfileViewController.h"
#import "SignupFlowViewController.h"
#import "SPVideoExtractor.h"
#import "User+Helper.h"

#define kShelbyChannelsStaleTime -600 //10 minutes
#define kShelbyTutorialMode @"kShelbyTutorialMode"

NSString * const kShelbyDVRDisplayChannelID = @"dvrDisplayChannel";
NSString * const kShelbyCommunityChannelID = @"521264b4b415cc44c9000001";

NSString *const kShelbyLastActiveDate = @"kShelbyLastActiveDate";
NSString *const kShelbyLastDashboardEntrySeen = @"kShelbyLastDashboardEntrySeen";

NSString * const kShelbyBrainFetchEntriesDidCompleteForChannelNotification = @"kShelbyBrainFetchEntriesDidCompleteForChannelNotification";
NSString * const kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification = @"kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification";
NSString * const kShelbyBrainFocusOnEntityNotification = @"kShelbyBrainFocusOnEntityNotification";
NSString * const kShelbyBrainChannelKey = @"channel";
NSString * const kShelbyBrainChannelEntriesKey = @"channelEntries";
NSString * const kShelbyBrainCachedKey = @"cached";
NSString * const kShelbyBrainEntityKey = @"entity";

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

@property (nonatomic, strong) UIAlertView *currentAlertView;

@property (nonatomic, assign) BOOL openingUserProfileInProgress;
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
    
    [self.signupFlowVC handleDidBecomeActive];

    //see method comments for explanation
    [self refreshUsersStreamAfterDelay];
    
    [[ShelbyNotificationManager sharedInstance] cancelAllNotifications];
    
    self.openingUserProfileInProgress = NO;
}

- (void)handleWillResignActive
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kShelbyLastActiveDate];

    DisplayChannel *mainChannel = [self getMainChannel];
    NSArray *entries = [self.homeVC entriesForChannel:mainChannel];
    // Save last video seen by user.
    if (entries && [entries count] > 0) {
        NSString *lastDahsboardEntryID = ((DashboardEntry *)entries[0]).dashboardEntryID;
        [[NSUserDefaults standardUserDefaults] setObject:lastDahsboardEntryID forKey:kShelbyLastDashboardEntrySeen];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];

    [self.homeVC handleWillResignActive];
    [User sessionDidPause];
}

- (void)handleDidFinishLaunching
{
    [ShelbyDataMediator sharedInstance].delegate = self;

    // This needs to be done before we decide what VC to activate
    // If welcome screen is completed and user started the signup screen and never logged in.
    // We should not reset Welcome screen in the case where user didn't even open signup, because maybe they just went for perview app.
    // Odd case is, user finished welcome, going to preview, then hit signup, kill the app... and now next time they open, we will take them to welcome again.
    if ([WelcomeViewController isWelcomeComplete]) {
        if ([SignupFlowViewController signupStatus] == ShelbySignupStatusStarted) {
            // Cleanup cache, logout user to prevent funcky case when a user that logged-in in the past tries to go thru signup but kills the app in the middle
            [SignupFlowViewController setSignupStatus:ShelbySignupStatusUnstarted];
            [[ShelbyDataMediator sharedInstance] logoutCurrentUser];
         if (![[ShelbyDataMediator sharedInstance] hasUserLoggedIn]) {
             [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusUnstarted];
             [[ShelbyDataMediator sharedInstance] nuclearCleanup];
            }
        }
    }
    
    if (![WelcomeViewController isWelcomeComplete]) {
        [self activateWelcomeViewController];
    } else {
        [self activateHomeViewController];
        User *currentUser = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
        if (currentUser) {
            [self fetchUserChannelsForceSwitchToUsersStream:YES];
            [[ShelbyDataMediator sharedInstance] updateRollFollowingsForCurrentUser];
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
    
    // When user goes to login, reset signup status.
    if ([SignupFlowViewController signupStatus] == ShelbySignupStatusStarted) {
        [SignupFlowViewController setSignupStatus:ShelbySignupStatusUnstarted];
    }
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
    User *currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    if (currentUser) {
        [self goToUsersStream];
    } else {
        [self goToCommunityChannel];
    }
    
    [[ShelbyNotificationManager sharedInstance] localNotificationFired:notification];
}

// Return the main channel for the user - Featured for logged out, MyStream for logged in
- (DisplayChannel *)getMainChannel
{
    User *currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    DisplayChannel *channel = nil;
    if (currentUser) {
        channel = [currentUser displayChannelForMyStream];
    } else {
        channel = [DisplayChannel fetchChannelWithDashboardID:kShelbyCommunityChannelID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
    }

    return channel;
}

- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    DisplayChannel *channel = [self getMainChannel];
    
    Dashboard *dashboard = nil;
    if (channel) {
        dashboard = channel.dashboard;

        __block NSArray *curEntries = [DashboardEntry entriesForDashboard:dashboard inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];

        [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:channel withCompletionHandler:^(DisplayChannel *displayChannel, NSArray *entries) {

            NSPredicate *onlyPlayableVideos = [NSPredicate predicateWithBlock:^BOOL(id entry, NSDictionary *bindings) {
                return [entry isPlayable];
            }];
            entries = [entries filteredArrayUsingPredicate:onlyPlayableVideos];

            NSDictionary *testDictionary = [[ShelbyABTestManager sharedInstance] activeBucketForTest:kShelbyABTestNotification];
            NSString *notificationMessage = nil;
            if ([testDictionary isKindOfClass:[NSDictionary class]]) {
                NSString *bucketName = testDictionary[@"name"];
                // If Bucket A/C - See if there are more than 3 new videos and take name/nickname from users for notification. If there are no 3 new videos & in Bucket A/C/E/G/I/K then, don't add notification
                if ([bucketName isEqualToString:@"A"] || [bucketName isEqualToString:@"C"] ||
                    [bucketName isEqualToString:@"E"] || [bucketName isEqualToString:@"G"] ||
                    [bucketName isEqualToString:@"I"] || [bucketName isEqualToString:@"K"] ||
                    [bucketName isEqualToString:@"Default"]) {
                    NSMutableSet *nicknames = [[NSMutableSet alloc] init];
                    NSString *lastDashboardEntryID = [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyLastDashboardEntrySeen];
                    // Counter is just to make sure we look at the latest 20 videos.
                    NSInteger counter = 0;
                    for (DashboardEntry *dashboard in entries) {
                        if (counter > 20 || [lastDashboardEntryID isEqualToString:dashboard.dashboardEntryID]) {
                            break;
                        }
                        NSString *name = dashboard.frame.creator.name;
                        if (!name) {
                            name = dashboard.frame.creator.nickname;
                        }

                        if (name) {
                            [nicknames addObject:name];
                        }
                        
                        counter++;
                    }
                    if ([nicknames count] > 2) {
                        NSArray *nicknamesArray = [nicknames allObjects];
                        // TODO: KP KP: We might want to randomly select 3 names
                        notificationMessage = [NSString stringWithFormat:testDictionary[@"message"], nicknamesArray[0], nicknamesArray[1], nicknamesArray[2]];
                    }
                } else {
                    notificationMessage = testDictionary[@"message"];
                }
            }
            
            if (!entries) {
                completionHandler(UIBackgroundFetchResultNoData);
            } else {
                if (!curEntries) {
                    curEntries = @[];
                }
                
                if ([self.homeVC mergeCurrentChannelEntries:curEntries forChannel:displayChannel withChannelEntries:entries]) {
                    // Give some time for thumbnails to load in view - a little hackish
                    [self performSelector:@selector(callCompletionBlock:) withObject:completionHandler afterDelay:2];
                    
                    // If there is a notification message - schedule notification
                    if (notificationMessage) {
                        [[ShelbyNotificationManager sharedInstance] scheduleNotificationWithDay:[testDictionary[kShelbyABTestNotificationDay] integerValue] time:[testDictionary[kShelbyABTestNotificationTime] integerValue] andMessage:notificationMessage];
                    }
                    
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
            }
        }];
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

// Should only be called from performBackgroundFetchWithCompletionHandler method
- (void)callCompletionBlock:(void (^)(UIBackgroundFetchResult))completionHandler
{
    STVDebugAssert(completionHandler, @"Completion Handler in background fetch should not be nil");
    
    completionHandler(UIBackgroundFetchResultNewData);
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
        [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsDidLogin];
        [self userWasUpdated];
        [User sessionDidBecomeActive];
        [self dismissLoginVCCompletion:^{
            if (![WelcomeViewController isWelcomeComplete]) {
                // This is for the case where user does the following:
                // Installs the app, go thru welcome, hit signup and kill the app.
                // User reopens the app, go thru welcome again, but now logs in (as it was actually an existing user.) In this case, We want to make sure that the welcome flag is set correctly.
                [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusComplete];
            }
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
            [self.currentAlertView dismissWithClickedButtonIndex:0 animated:YES];
            self.currentAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [self.currentAlertView show];
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
        // Need to setCurrentUser again, in case there was an error and the user was removed.
        [self setCurrentUser:[self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:YES]];

        [self.currentAlertView dismissWithClickedButtonIndex:0 animated:YES];
        self.currentAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [self.currentAlertView show];
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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyBrainFetchEntriesDidCompleteForChannelNotification
                                                        object:self userInfo:@{kShelbyBrainChannelKey : channel,
                                                                               kShelbyBrainChannelEntriesKey : channelEntries,
                                                                               kShelbyBrainCachedKey : @(cached)}];
    
    if (self.postFetchInvocationForChannel && [channel objectID] && self.postFetchInvocationForChannel[channel.objectID]) {
        [self.postFetchInvocationForChannel[channel.objectID] invoke];
    }
}

-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                               withError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyBrainFetchEntriesDidCompleteForChannelWithErrorNotification object:self userInfo:@{kShelbyBrainChannelKey : channel}];
    
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
    if ([ShelbyErrorUtility isConnectionError:error]) {
        errorMessage = @"Please make sure you are connected to the Internet.";
    } else {
        errorMessage = @"Could not connect. Please try again later.";
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.currentAlertView) {
            self.currentAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [self.currentAlertView show];
        }
    });
}

#pragma mark - ShelbyStreamBrowseManagementDelegate Methods

// Method below is delegate method of the SPVideoReelProtocol & ShelbyBrowseProtocol
- (void)loadMoreEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    if (channel != self.dvrChannel) {
        //OPTIMIZE: could be smarter, don't ALWAYS send this fetch if we have an outstanding fetch
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyBrainFocusOnEntityNotification object:self userInfo:@{kShelbyBrainEntityKey : entity,
                                                                                                                            kShelbyBrainChannelKey : channel}];
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
        [[ShelbyDataMediator sharedInstance] userLoggedIn];
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
                                                     if (!error) {
                                                         [self dismissSigupVCCompletion:^{
                                                             //if we came from welcomeVC, switch over to homeVC (call is idempotent)
                                                             [self activateHomeViewController];
                                                             //make sure we're showing updated stream (whether we came from welcome or home)
                                                             [self fetchUserChannelsForceSwitchToUsersStream:YES];
                                                         }];
                                                     }
                                                 }];
}

- (void)signupFlowNavigationViewControllerWantsLogin:(SignupFlowNavigationViewController *)signupVC
{
    [self dismissSigupVCCompletion:^{
        [self presentLoginVC];
    }];
}

// Some of these methods are also for SettingsViewDelefate
#pragma mark - ShelbyUserProfileDelegate
// follow user is also called from another delegate..
- (void)followRoll:(NSString *)rollID
{
    [[ShelbyDataMediator sharedInstance] followRoll:rollID];
}

- (void)unfollowRoll:(NSString *)rollID
{
    [[ShelbyDataMediator sharedInstance] unfollowRoll:rollID];
}

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

- (void)openLikersViewForVideo:(NSString *)videoID withLikers:(NSMutableOrderedSet *)likers
{
    ShelbyLikersViewController *likersVC = [[ShelbyLikersViewController alloc] initWithNibName:@"ShelbyLikersView" bundle:nil];
    
    likersVC.localLikers = likers;
    likersVC.delegate = self;
    User *currentUser = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
    likersVC.currentUser = currentUser;
    
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while ([topViewController presentedViewController]) {
        topViewController = [topViewController presentedViewController];
    }
    
    [topViewController presentViewController:likersVC animated:YES completion:nil];
}

// This method is going to be called from two protocols.. not that great. Need to have a nicer protocols.
- (void)userProfileWasTapped:(NSString *)userID
{
    if (self.openingUserProfileInProgress) {
        return;
    }
    
    self.openingUserProfileInProgress = YES;
    
    [[ShelbyDataMediator sharedInstance] forceFetchUserWithID:userID inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext] completion:^(User *fetchedUser) {
        
        DisplayChannel *rollChannel = [[ShelbyDataMediator sharedInstance] fetchDisplayChannelOnMainThreadContextForRollID:fetchedUser.publicRollID];
        
        if (!rollChannel) {
            rollChannel = [DisplayChannel channelForTransientEntriesWithID:fetchedUser.publicRollID title:fetchedUser.nickname inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            Roll *userRoll = [Roll rollForDictionary:@{@"id" : fetchedUser.publicRollID} inContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
            rollChannel.roll = userRoll;
        }
        [[ShelbyDataMediator sharedInstance] fetchFramesInChannel:rollChannel withCompletionHandler:^(DisplayChannel *displayChannel, NSArray *entries) {
            ShelbyUserProfileViewController *userProfileVC = [[ShelbyUserProfileViewController alloc] initWithNibName:@"ShelbyHomeView-iPhone" bundle:nil];
            
            userProfileVC.masterDelegate = self;
            userProfileVC.channels = @[rollChannel];
            userProfileVC.profileUser = fetchedUser;
            User *currentUser = [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
            userProfileVC.currentUser = currentUser;
            
            UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
            while ([topViewController presentedViewController]) {
                topViewController = [topViewController presentedViewController];
            }
            
            [topViewController presentViewController:userProfileVC animated:YES completion:^{
                [userProfileVC setEntries:entries forChannel:displayChannel];
                [userProfileVC focusOnChannel:displayChannel];
                self.openingUserProfileInProgress = NO;
            }];
        }];
    }];
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

- (void)signupWithFacebook
{
    [[ShelbyDataMediator sharedInstance] createUserWithFacebook];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.currentAlertView dismissWithClickedButtonIndex:0 animated:YES];
        self.currentAlertView = [[UIAlertView alloc] initWithTitle:@"Error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [self.currentAlertView show];
   });
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
    [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusComplete];

    [self presentSignupVC];
}

- (void)welcomeDidTapSignupWithFacebook:(WelcomeViewController *)welcomeVC
{
    UIStoryboard *signupFlowStoryboard = [UIStoryboard storyboardWithName:@"SignupFlow" bundle:nil];
    self.signupFlowVC = (SignupFlowNavigationViewController *)[signupFlowStoryboard instantiateInitialViewController];
    self.signupFlowVC.signupDelegate = self;
    
    [self.mainWindow.rootViewController presentViewController:self.signupFlowVC animated:YES completion:^{
        [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusComplete];
        [self.signupFlowVC startWithFacebookSignup];
    }];
}

- (void)welcomeDidTapLogin:(WelcomeViewController *)welcomeVC
{
    [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusComplete];

    [self presentLoginVC];
}

- (void)welcomeDidTapPreview:(WelcomeViewController *)welcomeVC
{
    [WelcomeViewController setWelcomeScreenComplete:ShelbyWelcomeStatusComplete];
    // When a user goes to preview, we want to make sure that if he ever started the signup process and stopped in the middle, we reset that. To make sure we don't reset the welcome screen and open it again.
    if ([SignupFlowViewController signupStatus] == ShelbySignupStatusStarted) {
        [SignupFlowViewController setSignupStatus:ShelbySignupStatusUnstarted];
    }
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

- (void)loginWithFacebook:(LoginViewController *)loginVC
{
    [[ShelbyDataMediator sharedInstance] loginUserFacebook];
}

//mirror method signupFlowNavigationViewControllerWantsLogin: implemented above

@end
