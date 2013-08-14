//
//  ShelbyDataMediator.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyDataMediator.h"

#import "Dashboard+Helper.h"
#import "DisplayChannel+Helper.h"
#import "DashboardEntry+Helper.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "GAI.h"
#import "Roll+Helper.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyAPIClient.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

NSString * const kShelbyOfflineLikesID = @"kShelbyOfflineLikesID";
NSString * const kShelbyNotificationFacebookConnectCompleted = @"kShelbyNotificationFacebookConnectCompleted";
NSString * const kShelbyNotificationTwitterConnectCompleted = @"kShelbyNotificationTwitterConnectCompleted";
NSString * const kShelbyNotificationUserSignupDidSucceed = @"kShelbyNotificationUserSignupDidSucceed";
NSString * const kShelbyNotificationUserSignupDidFail = @"kShelbyNotificationUserSignupDidFail";
NSString * const kShelbyNotificationUserUpdateDidSucceed = @"kShelbyNotificationUserUpdateDidSucceed";
NSString * const kShelbyNotificationUserUpdateDidFail = @"kShelbyNotificationUserUpdateDidFail";

@interface ShelbyDataMediator()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainThreadMOC;
@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@end

@implementation ShelbyDataMediator

+ (ShelbyDataMediator *)sharedInstance
{
    static ShelbyDataMediator *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self initMOCs];
    }
    return self;
}

- (void)fetchGlobalChannels
{
    //not sending back channels in cache b/c they're not all the "global" ones (ie. come from API, for all users)

    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchGlobalChannelsWithBlock:^(id JSON, NSError *error) {
        if(JSON){
            // doing all on main thread, seems premature to optimize here
            NSArray *channels = [self findOrCreateChannelsForJSON:JSON inContext:[self mainThreadMOC]];
            [self.delegate fetchGlobalChannelsDidCompleteWith:channels fromCache:NO];
        } else {
            [self.delegate fetchGlobalChannelsDidCompleteWithError:error];
        }
    }];
}

- (void)fetchAllUnsyncedLikes
{
    DisplayChannel *likesChannel = [DisplayChannel channelForOfflineLikesInContext:[self mainThreadContext]];
    NSArray *channelEntries = [likesChannel.roll.frame allObjects];
    
    NSSortDescriptor *sortLikes = [NSSortDescriptor sortDescriptorWithKey:@"clientLikedAt" ascending:NO];
    channelEntries = [channelEntries sortedArrayUsingDescriptors:@[sortLikes]];
    [self.delegate fetchOfflineLikesDidCompleteForChannel:likesChannel with:channelEntries];
}

- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForRollID:(NSString *)rollID
{
    return [DisplayChannel fetchChannelWithRollID:rollID inContext:[self mainThreadContext]];
}

- (DisplayChannel *)fetchDisplayChannelOnMainThreadContextForDashboardID:(NSString *)dashboardID
{
    return [DisplayChannel fetchChannelWithDashboardID:dashboardID inContext:[self mainThreadContext]];
}

- (void)fetchEntriesInChannel:(DisplayChannel *)channel sinceEntry:(NSManagedObject *)entry
{
    if(!channel.canFetchRemoteEntries){
        //djs should probably do a local fetch and update accordingly
        //but, we only have 1 special case right now.
        //so, until we have logic to properly handle this...
        return;
    }
    
    if(channel.roll && (!entry || [entry isKindOfClass:[Frame class]])){
        [self fetchFramesForRoll:channel.roll inChannel:channel sinceFrame:(Frame *)entry];
    } else if(channel.dashboard && (!entry || [entry isKindOfClass:[DashboardEntry class]])){
        NSString *authToken = nil;
        User *currentUser = [self fetchAuthenticatedUserOnMainThreadContext];
        if (currentUser) {
            authToken = currentUser.token;
        }
        [self fetchDashboardEntriesForDashboard:channel.dashboard inChannel:channel sinceDashboardEntry:(DashboardEntry *)entry withAuthToken:authToken];
    } else {
        STVAssert(NO, @"asked to fetch entries in channel with bad parameters");
    }
}


- (User *)fetchUserWithID:(NSString *)userID inContext:(NSManagedObjectContext *)context completion:(void (^)(User *fetchedUser))completion
{
    STVAssert(completion, @"expected a completion block");
    User *localUser = [User findUserWithID:userID inContext:context];
    if (localUser) {
        return localUser;
    } else {

        [ShelbyAPIClient fetchUserForUserID:userID andBlock:^(id JSON, NSError *error) {
            if (JSON && JSON[@"result"] && [JSON[@"result"] isKindOfClass:[NSDictionary class]]) {
                //we are now on main thread, but that may not be right for the context we were given
                [context performBlock:^{
                    User *fetchedUser = [User userForDictionary:JSON[@"result"] inContext:context];
                    completion(fetchedUser);
                }];
            } else {
                completion(nil);
            }
        }];
        return nil;
    }
}

- (void)likeFrame:(Frame *)frame forUser:(User *)user
{
    //Do Like
    [ShelbyAPIClient postUserLikedFrame:frame.frameID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON) { // success
            frame.clientUnsyncedLike = @0;
            frame.clientLikedAt = nil;
            //API is NOT returning the liked frame, so...
            [self fetchEntriesInChannel:[user displayChannelForLikesRoll] sinceEntry:nil];
            
            NSError *err;
            [frame.managedObjectContext save:&err];
            STVDebugAssert(!error, @"context save failed, in toggleLikeForFrame when liking (in block)...");
            if (err) {
                [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                      action:kAnalyticsIssueContextSaveError
                                                       label:[NSString stringWithFormat:@"-[likeFrame:forUser:] error: %@", err]];
            }
        } else {
            DLog(@"Failed to like!  DEBUG this %@", error);
        }
    }];
}


- (void)unlikeFrame:(Frame *)frame forUser:(User *)user
{
    [ShelbyAPIClient deleteFrame:frame.frameID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            NSError *err;
            [frame.managedObjectContext save:&err];
            STVDebugAssert(!err, @"context save failed, in toggleLikeForFrame when deleting (in block)...");
            if (err) {
                [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                      action:kAnalyticsIssueContextSaveError
                                                       label:[NSString stringWithFormat:@"-[unlikeFrame:forUser:] error: %@", err]];
            }
            
            //djs
            //TODO: need to smartly update the Browse View b/c the unliked frame is still in there :(
            //... until next launch
        } else {
            DLog(@"Failed to delete liked frame, DEBUG this %@", error);
        }
    }];

}

- (void)toggleUnsyncedLikeForFrame:(Frame *)frame
{
    BOOL shouldBeLiked = ![frame.clientUnsyncedLike boolValue];

    frame.clientUnsyncedLike = shouldBeLiked ? @1 : @0;
    
    if (frame.clientUnsyncedLike) {
        frame.clientLikedAt = [NSDate date];
    } else {
        frame.clientLikedAt = nil;
    }
    
    NSError *err;
    [frame.managedObjectContext save:&err];
    STVDebugAssert(!err, @"context save failed, in toggleLikeForFrame...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[toggleUnsyncedLikeForFrame:] error: %@", err]];
    }
}

//when login is enabled, this needs to be re-thought...
- (BOOL)toggleLikeForFrame:(Frame *)frame
{
    STVDebugAssert(frame.managedObjectContext == [self mainThreadContext], @"frame expected on main context (b/c action is from there)");
    
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
    
    if (user) {
        if (![user hasLikedVideoOfFrame:frame]) {
            [self likeFrame:frame forUser:user];
            
            //represent liked state until the API call succeeds
            frame.clientUnsyncedLike = @1;
            frame.clientLikedAt = [NSDate date];
            
            return YES;
            
        } else {
            //Do Unlike
            Frame *likedFrame = [user likedFrameWithVideoOfFrame:frame];
            STVDebugAssert(likedFrame, @"expected liked frame");
 
            [self unlikeFrame:frame forUser:user];
            
            //represnt unliked state assuming the API call succeeds
            frame.clientUnsyncedLike = @0;
            frame.clientLikedAt = nil;
            likedFrame.clientUnliked = @1;
            return NO;
        }
        
    } else {
        //not logged in
        BOOL shouldBeLiked = ![frame.clientUnsyncedLike boolValue];
        [self toggleUnsyncedLikeForFrame:frame];
        
        //djs TODO: I don't like that we're fetching all unsynced likes here
        //we should just signal the addition/removal of a single frame
        [self fetchAllUnsyncedLikes];
        
        return shouldBeLiked;
    }
}

- (User *)fetchAuthenticatedUserOnMainThreadContext
{
    return [self fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:NO];
}

- (User *)fetchAuthenticatedUserOnMainThreadContextWithForceRefresh:(BOOL)forceRefresh
{
    return [User currentAuthenticatedUserInContext:[self mainThreadContext] forceRefresh:forceRefresh];
}


- (void)fetchFramesForRoll:(Roll *)roll
                 inChannel:(DisplayChannel *)channel
                sinceFrame:(Frame *)sinceFrame
{
    if(!sinceFrame){
        //1) send back anything we have cached (all on main thread)
        NSArray *cachedFrames = [Frame framesForRoll:roll inContext:roll.managedObjectContext];
        if(cachedFrames && [cachedFrames count]){
            //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
            [self.delegate fetchEntriesDidCompleteForChannel:channel
                                                        with:cachedFrames
                                                   fromCache:YES];
        }
    }

    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchFramesForRollID:roll.rollID
                               sinceEntry:sinceFrame
                                withBlock:^(id JSON, NSError *error) {
            if(JSON){
                // 1) store this in core data (with a new background context)
                [self privateContextPerformBlock:^(NSManagedObjectContext *privateMOC) {
                    DisplayChannel *privateContextChannel = (DisplayChannel *)[privateMOC objectWithID:channel.objectID];
                    Roll *privateContextRoll = (Roll *)[privateMOC objectWithID:roll.objectID];
                    NSArray *frames = [self findOrCreateFramesForJSON:JSON
                                                             withRoll:privateContextRoll
                                                            inContext:privateMOC];
                    privateContextChannel.roll.frame = [NSSet setWithArray:frames];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSManagedObjectContext *mainMOC = [self mainThreadMOC];
                        NSMutableArray *results = [@[] mutableCopy];
                        //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                        for (Frame *frame in frames) {
                            Frame *mainThreadFrame = (Frame *)[mainMOC objectWithID:frame.objectID];
                            [results addObject:mainThreadFrame];
                        }
                        [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[mainMOC objectWithID:channel.objectID]
                                                                    with:results
                                                               fromCache:NO];
                    });
                }];                
            } else {
                [self.delegate fetchEntriesDidCompleteForChannel:channel
                                                       withError:error];
                DLog(@"fetch error: %@", error);
            }
    }];
}

-(void) fetchDashboardEntriesForDashboard:(Dashboard *)dashboard
                                inChannel:(DisplayChannel *)channel
                      sinceDashboardEntry:(DashboardEntry *)sinceDashboardEntry
                            withAuthToken:(NSString *)authToken
{
    if(!sinceDashboardEntry){
        // 1) send back anything we have cached (all on main thread)
        NSManagedObjectContext *mainMOC = [self mainThreadMOC];
        // could use relationship on dashboard, but instead using this helper to get dashboard entries in correct order
        NSArray *cachedDashboardEntries = [DashboardEntry entriesForDashboard:dashboard
                                                                    inContext:mainMOC];
        if(cachedDashboardEntries && [cachedDashboardEntries count]){
            //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
            [self.delegate fetchEntriesDidCompleteForChannel:channel
                                                        with:cachedDashboardEntries
                                                   fromCache:YES];
        }
    }

    //2) fetch remotely NB: AFNetworking returns us to the main thread
    [ShelbyAPIClient fetchDashboardEntriesForDashboardID:dashboard.dashboardID
                                              sinceEntry:sinceDashboardEntry
                                           withAuthToken:authToken
                                                andBlock:^(id JSON, NSError *error) {
        if(JSON){            
            // 1) store this in core data (in a new background context)
            [self privateContextPerformBlock:^(NSManagedObjectContext *privateMOC) {
                Dashboard *privateContextDashboard = (Dashboard *)[privateMOC objectWithID:dashboard.objectID];
                NSArray *dashboardEntries = [self findOrCreateDashboardEntriesForJSON:JSON
                                                                        withDashboard:privateContextDashboard
                                                                            inContext:privateMOC];
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSManagedObjectContext *mainMOC = [self mainThreadMOC];
                    NSMutableArray *results = [@[] mutableCopy];
                    //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                    for (DashboardEntry *dashboardEntry in dashboardEntries) {
                        DashboardEntry *mainThreadDashboardEntry = (DashboardEntry *)[mainMOC objectWithID:dashboardEntry.objectID];
                        [results addObject:mainThreadDashboardEntry];
                    }
                    [self.delegate fetchEntriesDidCompleteForChannel:(DisplayChannel *)[mainMOC objectWithID:channel.objectID]
                                                                with:results
                                                           fromCache:NO];
                });
            }];

        } else {
            [self.delegate fetchEntriesDidCompleteForChannel:channel
                                                   withError:error];
        }
    }];
}

- (void)syncLikes
{
    NSManagedObjectContext *moc = [self mainThreadContext];
    DisplayChannel *likesChannel = [DisplayChannel channelForOfflineLikesInContext:moc];
    NSArray *channelEntries = [likesChannel.roll.frame allObjects];

    User *user = [User currentAuthenticatedUserInContext:moc];
    
    for (Frame *frame in channelEntries) {
        [self likeFrame:frame forUser:user];
        //TODO: remove this from the offline likes channel
    }

    [self.delegate fetchOfflineLikesDidCompleteForChannel:likesChannel with:nil];
}

- (void)cleanupSession
{
    [[FacebookHandler sharedInstance] facebookCleanup];
}

- (void)clearAllCookies
{
    NSHTTPCookieStorage *cookieStore = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStore.cookies) {
        [cookieStore deleteCookie:cookie];
    }
}

- (void)logoutCurrentUser
{
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];

    NSManagedObjectContext *mainContext = [self mainThreadContext];
    NSArray *userChannels = [User channelsForUserInContext:mainContext];
    for (DisplayChannel *displayChannel in userChannels) {
        [mainContext deleteObject:displayChannel];
    }

    user.token = nil;
    [self cleanupSession];
    [self clearAllCookies];
    
    NSError *err;
    [[self mainThreadContext] save:&err];
    STVDebugAssert(!err, @"context save failed, put your DEBUG hat on...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[logoutCurrentUser] error: %@", err]];
        [self nuclearCleanup];
    }
}

- (void)loginUserWithEmail:(NSString *)email password:(NSString *)password
{
    [ShelbyAPIClient loginUserWithEmail:email password:password andBlock:^(id JSON, NSError *error) {
  
        if (JSON) {
            NSManagedObjectContext *context = [self mainThreadContext];
            NSDictionary *result = JSON[@"result"];
            if ([result isKindOfClass:[NSDictionary class]]) {
                User *user = [User userForDictionary:result inContext:context];
                NSError *err;
                [user.managedObjectContext save:&err];
                STVDebugAssert(!err, @"context save failed, put your DEBUG hat on...");
                if (err) {
                    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                          action:kAnalyticsIssueContextSaveError
                                                           label:[NSString stringWithFormat:@"-[loginUserWithEmail:password:] error: %@", err]];
                }
                [self.delegate loginUserDidComplete];
                [self syncLikes];
                [ShelbyAPIClient putGoogleAnalyticsClientID:[GAI sharedInstance].defaultTracker.clientId forUser:user];
                return;
            }
        }

        NSString *errorMessage = nil;
        // Error code -1009 - no connection
        // Error code -1001 - timeout
        if ([error code] == -1009 || [error code] == -1001) {
            errorMessage = @"Please make sure you are connected to the Internet";
        } else {
            errorMessage = @"Please make sure you've entered your login credientials correctly.";
        }
        
        [self.delegate loginUserDidCompleteWithError:errorMessage];
    }];
}

- (void)saveUserFromJSON:(id)JSON
{
    NSManagedObjectContext *context = [self mainThreadContext];
    NSDictionary *result = JSON[@"result"];
    if ([result isKindOfClass:[NSDictionary class]]) {
        User *user = [User userForDictionary:result inContext:context];
        NSError *err;
        [user.managedObjectContext save:&err];
        STVDebugAssert(!err, @"context after saveUserFromJSON");
        if (err) {
            [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                  action:kAnalyticsIssueContextSaveError
                                                   label:[NSString stringWithFormat:@"-[saveUserFromJSON:] error: %@", err]];
        }
        [self syncLikes];
        [ShelbyAPIClient putGoogleAnalyticsClientID:[GAI sharedInstance].defaultTracker.clientId forUser:user];
        return;
    }
}

- (void)createUserWithName:(NSString *)name andEmail:(NSString *)email
{
    __weak ShelbyDataMediator *weakSelf = self;
    [ShelbyAPIClient postSignupWithName:name email:email andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [weakSelf saveUserFromJSON:JSON];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidSucceed object:nil];
        } else {
            NSString *errorMessage = nil;
            if ([error isKindOfClass:[NSDictionary class]]) {
                NSDictionary *JSONError = (NSDictionary *)error;
                errorMessage = JSONError[@"message"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidFail object:errorMessage];
            
        }
    }];
}

- (void)updateUserName:(NSString *)name
              nickname:(NSString *)nickname
              password:(NSString *)password
                 email:(NSString *)email
                avatar:(UIImage *)avatar
            completion:(void (^)(NSError *error))completion
{
    NSMutableDictionary *params = [@{} mutableCopy];
    if (name) {
        params[kShelbyAPIParamName] = name;
    }
    
    if (nickname) {
        params[kShelbyAPIParamNickname] = nickname;
    }
    
    if (password) {
        params[kShelbyAPIParamPassword] = password;
        params[kShelbyAPIParamPasswordConfirmation] = password;
    }
    
    if (email) {
        params[kShelbyAPIParamEmail] = email;
    }

    if ([params count] == 0) {
        return;
    }

    //DS - You don't need a weak self here.  There's no retain cycle; self doesn't own the block.
    __weak ShelbyDataMediator *weakSelf = self;
    [ShelbyAPIClient putUserWithParams:params andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [weakSelf saveUserFromJSON:JSON];
            [self.delegate userWasUpdated];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserUpdateDidSucceed object:nil];
            if (avatar) {
                //start async user avatar upload
                [ShelbyAPIClient uploadUserAvatar:avatar andBlock:nil];
            }

        } else {
            NSString *errorMessage = nil;
            if ([error isKindOfClass:[NSDictionary class]]) {
                NSDictionary *JSONError = (NSDictionary *)error;
                errorMessage = JSONError[@"message"];
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserUpdateDidFail object:errorMessage];
        }
        if (completion) {
            completion(error);
        }
    }];
}

- (void)updateUserWithName:(NSString *)name
                  nickname:(NSString *)nickname
                  password:(NSString *)password
                     email:(NSString *)email
                    avatar:(UIImage *)avatar
                     rolls:(NSArray *)followRolls
                completion:(void (^)(NSError *error))completion
{
    User *user = [User currentAuthenticatedUserInContext:[self mainThreadMOC]];
    STVAssert(user.token, @"expect user to have a valid token (so we can follow rolls)");
    for (NSString *rollID in followRolls) {
        [self followRoll:rollID withAuthToken:user.token];
    }

    [self updateUserName:name
                nickname:nickname
                password:password
                   email:email
                  avatar:avatar
              completion:completion];
}

- (void)followRoll:(NSString *)rollID withAuthToken:(NSString *)authToken
{
    STVAssert(rollID && authToken, @"Expected rollID & authToken");
  
    [ShelbyAPIClient followRoll:rollID withAuthToken:authToken andBlock:^(id JSON, NSError *error) {
        if (!error) {
            // Fire and forget
        } else {
            // TODO: In the future, try to reschedule it
        }
    }];
}

- (void)userAskForFacebookPublishPermissions
{
    [self openFacebookSessionWithAllowLoginUI:NO andAskPublishPermissions:YES];
}

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    [self openFacebookSessionWithAllowLoginUI:allowLoginUI andAskPublishPermissions:NO];
}

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI andAskPublishPermissions:(BOOL)askForPublishPermission
{
    [[FacebookHandler sharedInstance] openSessionWithAllowLoginUI:YES
                                          andAskPublishPermission:askForPublishPermission
                                                        withBlock:^(NSDictionary *facebookUser,
                                                                                  NSString *facebookToken,
                                                                                  NSString *errorMessage) {
        User *user = nil;
        if (facebookUser) {
            NSManagedObjectContext *context = [self mainThreadContext];
            user = [User currentAuthenticatedUserInContext:context];
            //try adding token to the user
            [ShelbyAPIClient postThirdPartyToken:@"facebook"
                                   withAccountID:facebookUser[@"id"]
                                      oauthToken:facebookToken
                                     oauthSecret:nil
                                 shelbyAuthToken:user.token
                                        andBlock:^(id JSON, NSError *error) {
                                            if(!error){
                                                //user updated by API
                                                [user updateWithFacebookUser:facebookUser];
                                                NSError *err;
                                                [user.managedObjectContext save:&err];
                                                STVDebugAssert(!err, @"context save failed saving User after facebook login...");
                                                if (err) {
                                                    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                                                                          action:kAnalyticsIssueContextSaveError
                                                                                           label:[NSString stringWithFormat:@"-[openFacebookSessionWithAllowLoginUI:andAskPublishPermissions:] error: %@", err]];
                                                }
                                               
                                                [self.delegate facebookConnectDidComplete];
                                               
                                                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookConnectCompleted object:nil];

                                                if (askForPublishPermission) {
                                                    [[FacebookHandler sharedInstance] askForPublishPermissions];
                                                }
                                            } else {
                                                //did NOT add this auth to the current user
                                                [self.delegate facebookConnectDidCompleteWithError:nil];
                                            }
                                        }];
        } else if (facebookToken) {
            [self.delegate facebookConnectDidComplete];
        } else if (errorMessage) {
            [self.delegate facebookConnectDidCompleteWithError:errorMessage];
        }
     }];
}

- (void)connectTwitterWithViewController:(UIViewController *)viewController
{
    User *user = [User currentAuthenticatedUserInContext:[self mainThreadMOC]];
    NSString *token = nil;
    if (user) {
        token = user.token;
    }
    [[TwitterHandler sharedInstance] authenticateWithViewController:viewController withDelegate:self.delegate andAuthToken:token];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

// TODO: this should perform lightweight migrations
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if ( _persistentStoreCoordinator ) {
        return _persistentStoreCoordinator;
    }
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *applicationDocumentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Shelby.tv.sqlite"];
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    
    //djs TODO: handle this gracefully...
    //djs NB: IF you crash when updating CoreData, next run you can get an EXC_BAD_ACCESS on the following line
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
    {
        // Delete datastore if there's a conflict. User can re-login to repopulate the datastore.
        //djs TODO: perform lightweight migration when possible
        [fileManager removeItemAtURL:storeURL error:nil];
        
        // Retry
        if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error] )
        {
            DLog(@"Could not save changes to Core Data. Error: %@, %@", error, [error userInfo]);
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)mainThreadContext
{
    STVAssert([NSThread isMainThread], @"must only use main thread context on main thread");
    STVAssert(self.mainThreadMOC, @"we should probably get one of those :-P");
    return self.mainThreadMOC;
}

- (void)privateContextPerformBlock:(void (^)(NSManagedObjectContext *privateMOC))block
{
    STVAssert(self.privateContext, @"we should probalby get one of those :-P");
    [self.privateContext performBlock:^{
        block(self.privateContext);
    }];
}

- (void)privateContextPerformBlockAndWait:(void (^)(NSManagedObjectContext *privateMOC))block
{
    STVAssert(self.privateContext, @"we should probalby get one of those :-P");
    [self.privateContext performBlockAndWait:^{
        block(self.privateContext);
    }];
}

- (void)nuclearCleanup
{
    DLog(@"Destroying ManagedObjectContexts & PersistentStoreCoordinator");
    self.mainThreadMOC = nil;
    self.privateContext = nil;
    self.persistentStoreCoordinator = nil;
    
    DLog(@"Deleting Persistent Store Backing File");
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSURL *applicationDocumentsDirectory = [[fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *storeURL = [applicationDocumentsDirectory URLByAppendingPathComponent:@"Shelby.tv.sqlite"];
    [fileManager removeItemAtURL:storeURL error:nil];
    
    DLog(@"Recreating PersistentStoreCoordinator & ManagedObjectContexts");
    [self initMOCs];
    
    [self cleanupSession];
}

- (void)initMOCs
{
    _mainThreadMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainThreadMOC.persistentStoreCoordinator = [self persistentStoreCoordinator];
    _mainThreadMOC.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _mainThreadMOC.undoManager = nil;

    _privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _privateContext.persistentStoreCoordinator = [self persistentStoreCoordinator];
    _privateContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _privateContext.undoManager = nil;

    //automatically merge changes back and forth between private and main contexts
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_privateContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        DLog(@"merged changes private->main");
        [self.mainThreadMOC mergeChangesFromContextDidSaveNotification:note];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_mainThreadMOC queue:nil usingBlock:^(NSNotification *note) {
        DLog(@"main->private merged");
        [self.privateContext mergeChangesFromContextDidSaveNotification:note];
    }];
}

#pragma mark - Parsing Helpers
- (NSMutableArray *)loadDashboardEntries:(NSArray *)fromContextDashboardEntries intoContext:(NSManagedObjectContext *)moc
{
    NSMutableArray *intoContextDashboardEntries = [NSMutableArray arrayWithCapacity:[fromContextDashboardEntries count]];
    for (DashboardEntry *entry in fromContextDashboardEntries) {
        DashboardEntry *intoContextEntry = (DashboardEntry *)[[self mainThreadContext] objectWithID:entry.objectID];
        [intoContextDashboardEntries addObject:intoContextEntry];
    }

    return intoContextDashboardEntries;
}

- (NSMutableArray *)loadFrames:(NSArray *)fromContextFrames intoContext:(NSManagedObjectContext *)moc
{
    NSMutableArray *intoContextFrames = [NSMutableArray arrayWithCapacity:[fromContextFrames count]];
    for (Frame *entry in fromContextFrames) {
        Frame *intoContextEntry = (Frame *)[moc objectWithID:entry.objectID];
        [intoContextFrames addObject:intoContextEntry];
    }
    
    return intoContextFrames;
}

//djs TODO: make constant strings externs
//returns nil on error, otherwise array of DisplayChannel objects
- (NSArray *)findOrCreateChannelsForJSON:(id)JSON inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSInteger order = 0;
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *categoriesDictArray = jsonDict[@"result"];
    
    if(![categoriesDictArray isKindOfClass:[NSArray class]]){
        return nil;
    }
    
    NSMutableArray *resultDisplayChannels = [@[] mutableCopy];
    
    for (NSDictionary *category in categoriesDictArray) {
        if(![category isKindOfClass:[NSDictionary class]]){
            continue;
        }
        //each category dictionary looks like: { category_title: "", rolls: [], user_channels: [] }
        NSArray *rolls = category[@"rolls"];
        if([rolls isKindOfClass:[NSArray class]]){
            for (NSDictionary *roll in rolls) {
                if([roll isKindOfClass:[NSDictionary class]]){
                    DisplayChannel *channel = [DisplayChannel channelForRollDictionary:roll
                                                                             withOrder:order
                                                                             inContext:context];
                    order++;
                    [resultDisplayChannels addObject:channel];
                }
            }
        }
        NSArray *dashboards = category[@"user_channels"];
        if([dashboards isKindOfClass:[NSArray class]]){
            for (NSDictionary *dashboard in dashboards) {
                if([dashboard isKindOfClass:[NSDictionary class]]){
                    DisplayChannel *channel = [DisplayChannel channelForDashboardDictionary:dashboard
                                                                                  withOrder:order
                                                                                  inContext:context];
                    order++;
                    [resultDisplayChannels addObject:channel];
                }
            }
        }
    }
    
    NSError *err;
    [context save:&err];
    STVDebugAssert(!err, @"context save failed, put your DEBUG hat on...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[findOrCreateChannelsforJSON:inContext:] error: %@", err]];
    }
    return resultDisplayChannels;
}

- (NSArray *)findOrCreateFramesForJSON:(id)JSON withRoll:(Roll *)roll inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSDictionary *rollDictArray = jsonDict[@"result"];
    
    if(![rollDictArray isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSArray *frames = rollDictArray[@"frames"];
    if (![frames isKindOfClass:[NSArray class]]){
        return nil;
    }

    NSMutableArray *resultFrames = [@[] mutableCopy];
    
    for (NSDictionary *frameDict in frames) {
        if(![frameDict isKindOfClass:[NSDictionary class]]){
            continue;
        }
        
        Frame *entry = [Frame frameForDictionary:frameDict requireCreator:YES inContext:context];
 
        if (entry) {
            [resultFrames addObject:entry];
        }
    }
    
    NSError *err;
    [context save:&err];
    STVDebugAssert(!err, @"context save failed, in framesForJSON...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[findOrCreateFramesforJSON:withRoll:inContext:] error: %@", err]];
    }
    return resultFrames;
}

- (NSArray *)findOrCreateDashboardEntriesForJSON:(id)JSON withDashboard:(Dashboard *)dashboard inContext:(NSManagedObjectContext *)context
{
    if(![JSON isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *dashboardEntriesDictArray = jsonDict[@"result"];
    
    if(![dashboardEntriesDictArray isKindOfClass:[NSArray class]]){
        return nil;
    }
    
    NSMutableArray *resultDashboardEntries = [@[] mutableCopy];
    
    for (NSDictionary *dashboardEntryDict in dashboardEntriesDictArray) {
        if(![dashboardEntryDict isKindOfClass:[NSDictionary class]]){
            continue;
        }
        DashboardEntry *entry = [DashboardEntry dashboardEntryForDictionary:dashboardEntryDict
                                                              withDashboard:dashboard
                                                                  inContext:context];
        if (entry) {
            [resultDashboardEntries addObject:entry];
        }
    }
    
    NSError *err;
    [context save:&err];
    STVDebugAssert(!err, @"context save failed, put your DEBUG hat on...");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                         action:kAnalyticsIssueContextSaveError
                                          label:[NSString stringWithFormat:@"-[findOrCreateDashboardEntriesForJSON:withDashboard:inContext:] error: %@", err]];
    }
    return resultDashboardEntries;
}

@end
