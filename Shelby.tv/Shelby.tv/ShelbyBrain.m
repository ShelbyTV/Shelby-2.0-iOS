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
#import "Roll+Helper.h"
#import "ShelbyModel.h"
#import "SPVideoExtractor.h"
#import "ShelbyAlertView.h"
#import "User+Helper.h"

#define kShelbyChannelsStaleTime -600 //10 minutes
#define kShelbyTutorialMode @"kShelbyTutorialMode"

NSString * const kShelbyDVRDisplayChannelID = @"dvrDisplayChannel";
NSString * const kShelbyCommunityChannelID = @"515d83ecb415cc0d1a025bfe";

@interface ShelbyBrain()

//our two primary view controllers
@property (strong, nonatomic) WelcomeFlowViewController *welcomeVC;
@property (strong, nonatomic) ShelbyHomeViewController *homeVC;

//login and signup view controllers
@property (strong, nonatomic) LoginViewController *loginVC;
@property (strong, nonatomic) SignupFlowNavigationViewController *signupFlowVC;

@property (nonatomic, strong) NSDate *channelsLoadedAt;
@property (nonatomic, strong) DisplayChannel *currentChannel;

@property (nonatomic, assign) SPTutorialMode currentPlayerTutorialMode;
@property (nonatomic, assign) ShelbyBrowseTutorialMode currentBrowseTutorialMode;

@property (nonatomic, strong) NSMutableArray *cachedFetchedChannels;
@property (nonatomic, strong) NSMutableArray *remoteFetchedChannels;
@property (nonatomic, strong) DisplayChannel *dvrChannel;
@property (nonatomic, strong) DisplayChannel *offlineLikesChannel;

@property (nonatomic, strong) ShelbyDVRController *dvrController;

@property (nonatomic, strong) NSDictionary *postFetchInvocationForChannel;
@end

@implementation ShelbyBrain

- (void)handleDidBecomeActive
{
 
}

- (void)handleDidFinishLaunching
{
    [ShelbyDataMediator sharedInstance].delegate = self;
    
    if (![WelcomeFlowViewController isWelcomeComplete]) {
        [self activateWelcomeFlowViewController];
    } else {
        [self activateHomeViewController];
    }
    [self.mainWindow makeKeyAndVisible];
}

- (void)activateWelcomeFlowViewController
{
    UIStoryboard *welcomeStoryboard = [UIStoryboard storyboardWithName:@"WelcomeFlow" bundle:nil];
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
  
    // If user is not logged in, fetch unsynced likes. (KP KP: We might want to still fetch/merge unsynced likes with Likes Roll for logged in user)
    if (!currentUser) {
        [[ShelbyDataMediator sharedInstance] fetchAllUnsyncedLikes];
    } else {
        [self fetchUserChannelsForceSwitchToUsersStream:NO];
    }
    
    if(!self.channelsLoadedAt || [self.channelsLoadedAt timeIntervalSinceNow] < kShelbyChannelsStaleTime){
        if(!self.homeVC.channels){
            [self.homeVC.channelsLoadingActivityIndicator startAnimating];
        }
        [[ShelbyDataMediator sharedInstance] fetchChannels];
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

- (void)populateChannels
{
    NSMutableArray *allChannels = [self constructAllChannelsArray];
    for (DisplayChannel *channel in allChannels){
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

-(void)fetchChannelsDidCompleteWith:(NSArray *)channels fromCache:(BOOL)cached
{
    //channels come from CoreData and API

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
        [self populateChannels];
        self.channelsLoadedAt = [NSDate date];
    }
}

-(void)fetchChannelsDidCompleteWithError:(NSError *)error
{
    [self showErrorView:error];
    DLog(@"TODO: handle fetch channels did complete with error %@", error);
}

//channelEntries filled with ShelbyModel (specifically, a DashboardEntry or Frame)
-(void)fetchEntriesDidCompleteForChannel:(DisplayChannel *)channel
                                    with:(NSArray *)channelEntries
                               fromCache:(BOOL)cached
{
    STVAssert([NSThread isMainThread], @"expecting to be called on main thread");
    
    //the choke point where unplayable videos may not pass
    NSPredicate *onlyPlayableVideos = [NSPredicate predicateWithBlock:^BOOL(id entry, NSDictionary *bindings) {
        return [entry isPlayable];
    }];
    channelEntries = [channelEntries filteredArrayUsingPredicate:onlyPlayableVideos];
    
    NSArray *curEntries = [self.homeVC entriesForChannel:channel];
    if(curEntries && [curEntries count] && [channelEntries count]){
        ShelbyArrayMergeInstructions mergeInstructions = [self instructionsToMerge:channelEntries into:curEntries];
        if(mergeInstructions.shouldMerge){
            NSArray *newChannelEntries = [channelEntries subarrayWithRange:mergeInstructions.range];
            [self.homeVC addEntries:newChannelEntries toEnd:mergeInstructions.append ofChannel:channel];
            if(!mergeInstructions.append){
                [[SPVideoExtractor sharedInstance] warmCacheForVideoContainer:newChannelEntries[0]];
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
    
    ShelbyAlertView *alertView = [[ShelbyAlertView alloc] initWithTitle:@"Error" message:errorMessage dismissButtonTitle:@"OK" autodimissTime:8 onDismiss:nil];
    [alertView show];
}

#pragma mark - ShelbyStreamBrowseManagementDelegate Methods
- (void)userPressedChannel:(DisplayChannel *)channel atItem:(id)item
{
    // KP KP: TODO: prevent animated twice here and NOT in ShelbyHome. ---> same goes to Close animation
    NSArray *entriesForChannel = [self.homeVC entriesForChannel:channel];
    if (!entriesForChannel || ![entriesForChannel count]) {
        self.postFetchInvocationForChannel = nil;
        NSMethodSignature *channelPressed = [ShelbyBrain instanceMethodSignatureForSelector:@selector(userPressedChannel:atItem:)];
        NSInvocation *channelPressedInvocation = [NSInvocation invocationWithMethodSignature:channelPressed];
        [channelPressedInvocation setTarget:self];
        [channelPressedInvocation setSelector:@selector(userPressedChannel:atItem:)];
        [channelPressedInvocation setArgument:&channel atIndex:2];
        [channelPressedInvocation setArgument:&item atIndex:3];
        self.postFetchInvocationForChannel = @{[channel objectID] : channelPressedInvocation};
        return;
    }
    
    self.currentChannel = channel;
    
    NSInteger index = [self.homeVC indexOfDisplayedEntry:item inChannel:channel];
    if (index == NSNotFound) {
        // KP KP: TODO: what is the channel have no videos at all? Deal with that case
        index = 0;
    }
    [self.homeVC playChannel:channel atIndex:index];
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryBrowse withAction:kAnalyticsBrowseActionLaunchPlaylistSingleTap withLabel:channel.displayTitle];
}

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
    if (self.currentPlayerTutorialMode != SPTutorialModeNone) {
        self.currentPlayerTutorialMode = SPTutorialModeNone;
        self.currentBrowseTutorialMode = ShelbyBrowseTutorialModeEnd;
    }

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

- (SPTutorialMode)tutorialModeForCurrentPlayer
{
    return self.currentPlayerTutorialMode;
}

- (void)userDidCompleteTutorial
{
    self.currentBrowseTutorialMode = ShelbyBrowseTutorialModeNone;
    [self setTutorialCompleted];
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

typedef struct _ShelbyArrayMergeInstructions {
    bool shouldMerge;
    bool append;
    NSRange range;
} ShelbyArrayMergeInstructions;

#define NEWER_THAN_INTO_ARRAY NSNotFound

//NB: objects in array must repond to selector shelbyID
- (ShelbyArrayMergeInstructions)instructionsToMerge:(NSArray *)newArray into:(NSArray *)curArray
{
    ShelbyArrayMergeInstructions instructions;
    
    NSUInteger firstEntryIndex = [curArray indexOfObject:newArray[0]];
    NSUInteger lastEntryIndex = [curArray indexOfObject:[newArray lastObject]];
    if(firstEntryIndex == NSNotFound){
        //shelbyID is a MongoID which starts with timestamp
        if([[newArray[0] shelbyID] compare:[curArray[0] shelbyID]] == NSOrderedDescending){
            //first new element > first old element
            firstEntryIndex = NEWER_THAN_INTO_ARRAY;
        } else {
            firstEntryIndex = [curArray count];
        }
    }
    if(lastEntryIndex == NSNotFound){
        if([[[curArray lastObject] shelbyID] compare:[[newArray lastObject] shelbyID]] == NSOrderedDescending){
            //last old element > last new element
            lastEntryIndex = [curArray count];
        } else {
            lastEntryIndex = NEWER_THAN_INTO_ARRAY;
        }
        
    }
    
    if(firstEntryIndex == NEWER_THAN_INTO_ARRAY){
        if(lastEntryIndex == NEWER_THAN_INTO_ARRAY){
            //full prepend
            instructions.shouldMerge = YES;
            instructions.append = NO;
            instructions.range = NSMakeRange(0, [newArray count]);
        } else {
            //partial prepend
            instructions.shouldMerge = YES;
            instructions.append = NO;
            NSUInteger overlapIdx = [self indexOfFirstCommonObjectFromFront:YES of:curArray into:newArray];
            instructions.range = NSMakeRange(0, overlapIdx);
        }
    } else if(firstEntryIndex == [curArray count]){
        //full append
        instructions.shouldMerge = YES;
        instructions.append = YES;
        instructions.range = NSMakeRange(0, [newArray count]);
    } else if(lastEntryIndex < [curArray count]){
        //complete subset
        instructions.shouldMerge = NO;
    } else {
        //partial append
        instructions.shouldMerge = YES;
        instructions.append = YES;
        NSUInteger overlapIdx = [self indexOfFirstCommonObjectFromFront:NO of:curArray into:newArray];
        instructions.range = NSMakeRange(overlapIdx+1, [newArray count]-(overlapIdx+1));
    }
    
    return instructions;
}

//we know there is overlap, but it's possible that curArray[0] or [curArray lastObject] is not in newArray
//so, we try those first, then keep moving deeper into array
- (NSUInteger)indexOfFirstCommonObjectFromFront:(BOOL)front of:(NSArray *)curArray into:(NSArray *)newArray
{
    NSUInteger idx = NSNotFound;
    NSEnumerator *curArrayEnumerator = front ? [curArray objectEnumerator] : [curArray reverseObjectEnumerator];
    for (id obj in curArrayEnumerator) {
        idx = [newArray indexOfObject:obj];
        if(idx != NSNotFound){
            return idx;
        }
    }

    //din't find an overlap, allow for all of newArray to be returned
    return (front ? [newArray count] : -1);
}

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
    [[ShelbyDataMediator sharedInstance] logoutCurrentUser];
    self.currentUser = nil;

    [self goToCommunityChannel];
}

- (void)connectToFacebook
{
    [[ShelbyDataMediator sharedInstance] openFacebookSessionWithAllowLoginUI:YES];
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
    ShelbyAlertView *alertView =  [[ShelbyAlertView alloc] initWithTitle:@"Error" message:message dismissButtonTitle:@"OK" autodimissTime:3.0 onDismiss:nil];
    [alertView show];
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

- (ShelbyBrowseTutorialMode)browseTutorialMode
{
    return self.currentBrowseTutorialMode;
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

# pragma mark - WelcomeFlowDelegate

- (void)welcomeFlowDidTapSignup:(WelcomeFlowViewController *)welcomeFlowVC
{
    [self presentSignupVC];
}

- (void)welcomeFlowDidTapLogin:(WelcomeFlowViewController *)welcomeFlowVC
{
    [self presentLoginVC];
}

- (void)welcomeFlowDidTapPreview:(WelcomeFlowViewController *)welcomeFlowVC
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
