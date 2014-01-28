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
#import "GAIFields.h"
#import "Intercom.h"
#import "Roll+Helper.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyAPIClient.h"
#import "ShelbyErrorUtility.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

NSString * const kShelbyOfflineLikesID = @"kShelbyOfflineLikesID";
NSString * const kShelbyNotificationFacebookConnectCompleted = @"kShelbyNotificationFacebookConnectCompleted";
NSString * const kShelbyNotificationTwitterConnectCompleted = @"kShelbyNotificationTwitterConnectCompleted";
NSString * const kShelbyNotificationUserSignupDidSucceed = @"kShelbyNotificationUserSignupDidSucceed";
NSString * const kShelbyNotificationUserSignupDidFail = @"kShelbyNotificationUserSignupDidFail";
NSString * const kShelbyNotificationUserUpdateDidSucceed = @"kShelbyNotificationUserUpdateDidSucceed";
NSString * const kShelbyNotificationUserUpdateDidFail = @"kShelbyNotificationUserUpdateDidFail";
NSString * const kShelbyUserHasLoggedInKey = @"user_has_logged_in";

@interface ShelbyDataMediator()
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSManagedObjectContext *mainThreadMOC;
@property (nonatomic, strong) NSManagedObjectContext *privateContext;
@end

@implementation ShelbyDataMediator {
    id _mainContextObserver, _privateContextObserver;
}

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
            [self postNotificationForError:error];
            
            [self.delegate fetchGlobalChannelsDidCompleteWithError:error];
        }
    }];
}

- (void)fetchFeaturedChannelsWithCompletionHandler:(void (^)(NSArray *channels, NSError *error))completionHandler
{
    [ShelbyAPIClient fetchFeaturedChannelsWithBlock:^(id JSON, NSError *error) {
        if (JSON) {
            // doing all on main thread, seems premature to optimize here
            NSArray *channels = [self findOrCreateChannelsForJSON:JSON inContext:[self mainThreadContext]];
            completionHandler(channels, nil);
        } else {
            [self postNotificationForError:error];
            completionHandler(nil, error);
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
        //no need to crash, we can ignore this in production and still continue operating
        STVDebugAssert(NO, @"asked to fetch entries in channel with bad parameters. channel:%@ roll:%@ dashboard:%@ entry:%@", channel, channel.roll, channel.dashboard, entry);
    }
}

// KP KP: TODO: might want to refactor it with the other fetchEntriesInChannel method
- (void)fetchEntriesInChannel:(DisplayChannel *)channel withCompletionHandler:(shelby_data_mediator_complete_block_t)completionHandler
{
    User *currentUser = [self fetchAuthenticatedUserOnMainThreadContext];
    NSString *authToken = nil;
    if (currentUser) {
        authToken = currentUser.token;
    }

    Dashboard *dashboard = channel.dashboard;
    [ShelbyAPIClient fetchDashboardEntriesForDashboardID:channel.dashboard.dashboardID
                                              sinceEntry:nil
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
                                                                //OPTIMIZE: this makes N calls to the DB, could use an 'IN' predicate to do it in one call:
                                                                //[NSPredicate predicateWithFormat:@"identifier IN %@", identifiersOfRelatedObjects];
                                                                for (DashboardEntry *dashboardEntry in dashboardEntries) {
                                                                    DashboardEntry *mainThreadDashboardEntry = (DashboardEntry *)[mainMOC objectWithID:dashboardEntry.objectID];
                                                                    [results addObject:mainThreadDashboardEntry];
                                                                }
                                                                DisplayChannel *mainThreadChannel = (DisplayChannel *)[mainMOC objectWithID:channel.objectID];
                                                                completionHandler(mainThreadChannel, results);
                                                                
                                                            });
                                                        }];
                                                        
                                                    } else {
                                                        completionHandler(channel, nil);
                                                    }
                                                }];
}


// KP KP: TODO: might want to refactor it with the other fetchEntriesInChannel method
- (void)fetchFramesInChannel:(DisplayChannel *)channel withCompletionHandler:(shelby_data_mediator_complete_block_t)completionHandler
{
    Roll *roll = channel.roll;
    [ShelbyAPIClient fetchFramesForRollID:roll.rollID sinceEntry:nil
                                withBlock:^(id JSON, NSError *error) {
                                    if(JSON){
                                        // 1) store this in core data (with a new background context)
                                        [self privateContextPerformBlock:^(NSManagedObjectContext *privateMOC) {
                                            Roll *privateContextRoll = (Roll *)[privateMOC objectWithID:roll.objectID];
                                            NSArray *frames = [self findOrCreateFramesForJSON:JSON
                                                                                     withRoll:privateContextRoll
                                                                                    inContext:privateMOC];
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                NSManagedObjectContext *mainMOC = [self mainThreadMOC];
                                                NSMutableArray *results = [@[] mutableCopy];
                                                //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                                                //OPTIMIZE: this makes N calls to the DB, could use an 'IN' predicate to do it in one call:
                                                //[NSPredicate predicateWithFormat:@"identifier IN %@", identifiersOfRelatedObjects];
                                                for (Frame *frame in frames) {
                                                    Frame *mainThreadFrame = (Frame *)[mainMOC objectWithID:frame.objectID];
                                                    [results addObject:mainThreadFrame];
                                                }
                                                DisplayChannel *mainThreadChannel = (DisplayChannel *)[mainMOC objectWithID:channel.objectID];
                                                completionHandler(mainThreadChannel, results);
                                            });
                                        }];                
                                        
                                    } else {
                                        completionHandler(channel, nil);
                                    }
                                }];
}


- (void)fetchUserWithID:(NSString *)userID inContext:(NSManagedObjectContext *)context completion:(void (^)(User *fetchedUser))completion
{
    STVAssert(completion, @"expected a completion block");
    User *localUser = [User findUserWithID:userID inContext:context];
    if (localUser && localUser.publicRollID) {
        completion(localUser);
    } else {
        [self forceFetchUserWithID:userID inContext:context completion:completion];
    }
}

// TODO: KP KP: Can we cache these? and not force fetch everytime?
- (void)forceFetchUserWithID:(NSString *)userID
                   inContext:(NSManagedObjectContext *)context
                  completion:(void (^)(User *fetchedUser))completion
{
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
}

- (void)fetchFrameWithID:(NSString *)frameID
               inContext:(NSManagedObjectContext *)context
              completion:(void (^)(Frame *fetchedFrame))completion
{
    [ShelbyAPIClient fetchFrameForFrameID:frameID withBlock:^(id JSON, NSError *error) {
        if (JSON && JSON[@"result"] && [JSON[@"result"] isKindOfClass:[NSDictionary class]]) {
            [context performBlock:^{
                Frame *fetchedFrame = [Frame frameForDictionary:JSON[@"result"] requireCreator:NO inContext:context];
                completion(fetchedFrame);
            }];
        } else {
            completion(nil);
        }
    }];
}

- (void)fetchDashboardEntryWithID:(NSString *)dashboardID
                        inContext:(NSManagedObjectContext *)context
                       completion:(void (^)(DashboardEntry *fetchedDashboard))completion
{
    [ShelbyAPIClient fetchDashboardEntryForDashboardID:dashboardID withBlock:^(id JSON, NSError *error) {
        if (JSON && JSON[@"result"] && [JSON[@"result"] isKindOfClass:[NSDictionary class]]) {
            [context performBlock:^{
                DashboardEntry *fetchedDashboard = [DashboardEntry dashboardEntryForDictionary:JSON[@"result"] withDashboard:nil inContext:context];
                completion(fetchedDashboard);
            }];
        } else {
            completion(nil);
        }
    }];
}

- (void)fetchAllLikersOfVideo:(Video *)v completion:(void (^)(NSArray *))completion
{
    [ShelbyAPIClient fetchAllLikersOfVideo:v.videoID withBlock:^(id JSON, NSError *error) {
        if (JSON && JSON[@"result"] && [JSON[@"result"] isKindOfClass:[NSDictionary class]] &&
            JSON[@"result"][@"likers"] && [JSON[@"result"][@"likers"] isKindOfClass:[NSArray class]]) {
            [v.managedObjectContext performBlock:^{
                NSArray *likersArray = JSON[@"result"][@"likers"];
                NSMutableArray *likers = [NSMutableArray arrayWithCapacity:likersArray.count];
                for (NSDictionary *likerWrapper in likersArray) {
                    if (likerWrapper && [likerWrapper isKindOfClass:[NSDictionary class]] &&
                        likerWrapper[@"user"]) {
                        NSDictionary *likerUserDict = likerWrapper[@"user"];
                        User *likingUser = [User userForDictionary:likerUserDict inContext:v.managedObjectContext];
                        [likers addObject:likingUser];
                    }
                }
                
                NSError *err;
                [v.managedObjectContext save:&err];
                STVDebugAssert(!error, @"context save failed, in fetchAllLikersOfVideo");
                
                completion(likers);
            }];
        } else {
            completion(nil);
        }
    }];
}

- (void)likeFrame:(Frame *)frame forUser:(User *)user
{
    //Do Like
    [ShelbyAPIClient postUserLikedFrame:frame.frameID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON) { // success
            frame.clientUnsyncedLike = @0;
            frame.clientLikedAt = nil;
            //API is NOT returning the liked frame, but we need it when deleting, so...
            [self fetchEntriesInChannel:[user displayChannelForSharesRoll] sinceEntry:nil];
            
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
            [self.delegate removeFrame:frame fromChannel:[user displayChannelForSharesRoll]];

            [frame.managedObjectContext deleteObject:frame];
            NSError *err;
            [frame.managedObjectContext save:&err];
            STVDebugAssert(!error, @"context save failed, in unlikeFrame block...");

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

- (BOOL)likeFrame:(Frame *)frame
{
    STVDebugAssert(frame.managedObjectContext == [self mainThreadContext], @"frame expected on main context (b/c action is from there)");
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];
    
    if (user) {
        if (![user hasLikedVideoOfFrame:frame] && ![frame.roll.rollID isEqualToString:user.publicRollID]) {
            [self likeFrame:frame forUser:user];
            
            //represent liked state until the API call succeeds
            frame.clientUnsyncedLike = @1;
            [frame addUpvotersObject:user];
            frame.clientLikedAt = [NSDate date];

            NSError *err;
            [frame.managedObjectContext save:&err];
            STVDebugAssert(!err, @"context save failed, in toggleLikeForFrame...");

            return YES;
            
        } else {
            //asked to like, frame is already liked... fail
            return NO;
        }
        
    } else {
        //not logged in
        if ([frame.clientUnsyncedLike boolValue]) {
            //asked to like, frame is already liked... fail
            return NO;
        }
        [self toggleUnsyncedLikeForFrame:frame];
        [self fetchAllUnsyncedLikes];
        return YES;
    }
}

- (BOOL)unlikeFrame:(Frame *)frame
{
    STVDebugAssert(frame.managedObjectContext == [self mainThreadContext], @"frame expected on main context (b/c action is from there)");
    User *user = [self fetchAuthenticatedUserOnMainThreadContext];

    if (user) {
        if (![user hasLikedVideoOfFrame:frame]) {
            //asked to unlike, but user has not liked frame... fail
            return NO;
            
        } else {
            //Do Unlike
            Frame *likedFrame = [user likedFrameWithVideoOfFrame:frame];
            STVDebugAssert(likedFrame, @"expected liked frame");
            
            //represent unliked state assuming the API call will succeed
            frame.clientUnsyncedLike = @0;
            [frame removeUpvotersObject:user];
            frame.clientLikedAt = nil;
            likedFrame.clientUnliked = @1;

            NSError *err;
            [frame.managedObjectContext save:&err];
            STVDebugAssert(!err, @"context save failed, in toggleLikeForFrame...");

            [self unlikeFrame:likedFrame forUser:user];

            return YES;
        }
        
    } else {
        //not logged in
        if (![frame.clientUnsyncedLike boolValue]) {
            //asked to unlike, but user has not liked frame... fail
            return NO;
        }
        [self toggleUnsyncedLikeForFrame:frame];
        [self fetchAllUnsyncedLikes];
        return YES;
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
                    Roll *privateContextRoll = (Roll *)[privateMOC objectWithID:roll.objectID];
                    NSArray *frames = [self findOrCreateFramesForJSON:JSON
                                                             withRoll:privateContextRoll
                                                            inContext:privateMOC];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSManagedObjectContext *mainMOC = [self mainThreadMOC];
                        NSMutableArray *results = [@[] mutableCopy];
                        //OPTIMIZE: we can actually pre-fetch / fault all of these objects in, we know we need them
                        //OPTIMIZE: this makes N calls to the DB, could use an 'IN' predicate to do it in one call:
                        //[NSPredicate predicateWithFormat:@"identifier IN %@", identifiersOfRelatedObjects];
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
                [self postNotificationForError:error];
                
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
                    //OPTIMIZE: this makes N calls to the DB, could use an 'IN' predicate to do it in one call:
                    //[NSPredicate predicateWithFormat:@"identifier IN %@", identifiersOfRelatedObjects];
                    for (DashboardEntry *dashboardEntry in dashboardEntries) {
                        DashboardEntry *mainThreadDashboardEntry = (DashboardEntry *)[mainMOC objectWithID:dashboardEntry.objectID];
                        [results addObject:mainThreadDashboardEntry];
                    }
                    DisplayChannel *mainThreadChannel = (DisplayChannel *)[mainMOC objectWithID:channel.objectID];
                    [self.delegate fetchEntriesDidCompleteForChannel:mainThreadChannel
                                                                with:results
                                                           fromCache:NO];

                    if (sinceDashboardEntry && [results count] == 0) {
                        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryAppEventOfInterest
                                                              action:kAnalyticsAppEventLoadMoreReturnedEmpty
                                                               label:[mainThreadChannel displayTitle]];
                    }
                });
            }];

        } else {
            [self postNotificationForError:error];

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
    [Intercom endSession];
    [ShelbyAPIClient synchronousLogout];
    
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
        [self handleUserLoginWithJSON:JSON andError:error];
    }];
}

- (void)handleUserLoginWithJSON:(id)JSON andError:(NSError *)error
{
    if (JSON) {
        NSManagedObjectContext *context = [self mainThreadContext];
        NSDictionary *result = JSON[@"result"];
        if ([result isKindOfClass:[NSDictionary class]]) {
            User *user = [User userForDictionary:result inContext:context];
            [User sessionDidBecomeActive];
            [Intercom beginSessionForUserWithUserId:user.userID andEmail:user.email];
            [Intercom updateAttributes:@{@"ios" : @1,
                                         @"name" : user.name}];
            [self userLoggedIn];
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
            [self updateRollFollowingsForCurrentUser];
            id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
            [ShelbyAPIClient putGoogleAnalyticsClientID:[tracker get:kGAIClientId] forUser:user];
            return;
        }
    }
    
    NSString *errorMessage = nil;
    if ([ShelbyErrorUtility isConnectionError:error]) {
        errorMessage = @"Please make sure you are connected to the Internet";
    } else if ([error.domain isEqualToString:@"ShelbyAPIClient"] && error.code == 403001) {
        // This is an error message when a user tries to login with a FB/TW account. But that FB/TW account does not belong to a Shelby user.
        errorMessage = @"Shelby login not found. Try a different login, or Sign Up to create an account.";
    } else if ([error.domain isEqualToString:@"ShelbyAPIClient"] && error.code == 403002) {
        NSDictionary *errorInfo = error.userInfo;
        errorMessage = [self errorMessageForExistingAccountWithErrorDictionary:errorInfo];
    } else {
        errorMessage = @"Please make sure you've entered your login credientials correctly.";
    }
    
    [self.delegate loginUserDidCompleteWithError:errorMessage];
}

- (User *)saveUserFromJSON:(id)JSON
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
        id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
        [ShelbyAPIClient putGoogleAnalyticsClientID:[tracker get:kGAIClientId]  forUser:user];
        return user;
    }
    return nil;
}

- (void)handleCreateUserWithJSON:(id)JSON andError:(NSError *)error
{
    if (JSON) {
        User *newUser = [self saveUserFromJSON:JSON];
        if (newUser) {
            [Intercom beginSessionForUserWithUserId:newUser.userID andEmail:newUser.email];
            [Intercom updateAttributes:@{@"ios" : @1,
                                         @"name" : newUser.name ? newUser.name : newUser.nickname}];
            [self updateRollFollowingsForCurrentUser];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidSucceed
                                                                object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidFail
                                                                object:@"failed to create user from JSON response"];
        }
    } else {
        NSString *errorMessage = nil;
        // Not sure why error would be type dictionary...
        if ([error isKindOfClass:[NSDictionary class]]) {
            NSDictionary *JSONError = (NSDictionary *)error;
            errorMessage = JSONError[@"message"];
        } else if ([error isKindOfClass:[NSError class]] && [error.domain isEqualToString:@"ShelbyAPIClient"] && error.code == 403004) {
            errorMessage = @"You already have a Shelby account. Please login with Facebook.";
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserSignupDidFail object:errorMessage];
        
    }
}

- (void)createAnonymousUser
{
    [ShelbyAPIClient postCreateAnonymousUser:^(id JSON, NSError *error) {
        [self handleCreateUserWithJSON:JSON andError:error];
    }];
}

- (void)createUserWithName:(NSString *)name andEmail:(NSString *)email
{
    [ShelbyAPIClient postSignupWithName:name email:email andBlock:^(id JSON, NSError *error) {
        [self handleCreateUserWithJSON:JSON andError:error];
    }];
}

- (void)createUserWithFacebook
{
    [[FacebookHandler sharedInstance] openSessionWithAllowLoginUI:YES
                                          andAskPublishPermission:NO
                                                        withBlock:^(NSDictionary *facebookUser,
                                                                    NSString *facebookToken,
                                                                    NSString *errorMessage)
     {
         if (facebookUser) {
             [ShelbyAPIClient signupWithFacebookAccountID:facebookUser[@"id"]
                                              oauthToken:facebookToken
                                                andBlock:^(id JSON, NSError *error)
              {
                  [self handleCreateUserWithJSON:JSON andError:error];
                  if (error) {
                      // If there was a problem signup with FB - clean FB session
                      [self cleanupSession];
                  }
              }];
         } else {
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

    [ShelbyAPIClient putUserWithParams:params andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self saveUserFromJSON:JSON];
            [self.delegate userWasUpdated];
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationUserUpdateDidSucceed object:nil];
            if (avatar) {
                [ShelbyAPIClient uploadUserAvatar:avatar andBlock:^(id JSON, NSError *error) {
                    if (JSON) {
                        [self saveUserFromJSON:JSON];
                        [self.delegate userWasUpdated];
                    }
                }];
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

- (void)updateUserPreferenesForCurrentUser
{
    // PUSH NOTIFICATION: For now, push notifications settings for iOS are ALL or NOTHING.
    // We check the like_notifications_ios field but actually update also reroll_notifications_ios and roll_activity_notifications_ios
    // Once we implement the other two, we will have to add the fields to CoreData and corresponding rows in the table.
    User *currentUser = [self fetchAuthenticatedUserOnMainThreadContext];
    NSDictionary *prefs = @{@"like_notifications_ios" : currentUser.likeNotificationsIOS,
                            @"reroll_notifications_ios" : currentUser.likeNotificationsIOS,
                            @"roll_activity_notifications_ios" : currentUser.likeNotificationsIOS};
    
    NSDictionary *params = @{@"preferences" : prefs};
    [ShelbyAPIClient putUserWithParams:params andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self saveUserFromJSON:JSON];
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
        [self followRoll:rollID];
    }

    [self updateUserName:name
                nickname:nickname
                password:password
                   email:email
                  avatar:avatar
              completion:completion];
}

#pragma mark - Roll Followings
- (void)fetchRollFollowingsForUser:(User *)user withCompletion:(void (^)(User *user, NSArray *rawRollFollowings, NSError *error))completion
{
    NSParameterAssert(user);
    
    [ShelbyAPIClient fetchRollFollowingsForUser:user withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (JSON && JSON[@"result"] && [JSON[@"result"] isKindOfClass:[NSArray class]]) {
            //we are now on main thread, good
            [user updateRollFollowingsForArray:JSON[@"result"]];
            NSError *err;
            [user.managedObjectContext save:&err];
            STVDebugAssert(!err, @"context save failed on roll followings fetch");
            if (completion) {
                completion(user, JSON[@"result"], error);
            }
        } else {
            if (completion) {
                completion(user, nil, error);
            }
        }
    }];
}

- (void)updateRollFollowingsForCurrentUser
{
    User *user = [User currentAuthenticatedUserInContext:[self mainThreadMOC]];
    STVAssert(user.token, @"expect user to have token (so we can fetch roll followings)");
    
    [self fetchRollFollowingsForUser:user withCompletion:nil];
}

- (void)followRoll:(NSString *)rollID
{
    STVAssert(rollID, @"must pass rollID");
    User *user = [User currentAuthenticatedUserInContext:[self mainThreadMOC]];
    STVAssert(user.token, @"expect user to have a valid token (so we can follow rolls)");
    
    [ShelbyAPIClient followRoll:rollID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (!error) {
            [user didFollowRoll:rollID];
        } else {
            // TODO: In the future, try to reschedule it
        }
    }];
}

- (void)unfollowRoll:(NSString *)rollID
{
    STVAssert(rollID, @"must pass rollID");
    User *user = [User currentAuthenticatedUserInContext:[self mainThreadMOC]];
    STVAssert(user.token, @"expect user to have a valid token (so we can follow rolls)");
    
    [ShelbyAPIClient unfollowRoll:rollID withAuthToken:user.token andBlock:^(id JSON, NSError *error) {
        if (!error) {
            [user didUnfollowRoll:rollID];
        } else {
            // TODO: In the future, try to reschedule it
        }
    }];
}

- (void)loginUserFacebook
{
    [[FacebookHandler sharedInstance] openSessionWithAllowLoginUI:YES
                                          andAskPublishPermission:NO
                                                        withBlock:^(NSDictionary *facebookUser,
                                                                    NSString *facebookToken,
                                                                    NSString *errorMessage)
    {
        if (facebookUser) {
            [ShelbyAPIClient LoginWithFacebookAccountID:facebookUser[@"id"]
                                             oauthToken:facebookToken
                                               andBlock:^(id JSON, NSError *error)
            {
                [self handleUserLoginWithJSON:JSON andError:error];
                if (error) {
                    // If there was a problem login with FB - clean FB session 
                    [self cleanupSession];
                }
            }];
        } else {
            [self.delegate loginUserDidCompleteWithError:@"Go to Settings -> Privacy -> Facebook and turn Shelby ON"];
        }
    }];
}

- (BOOL)hasUserLoggedIn
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kShelbyUserHasLoggedInKey] == YES;
}

- (void)userLoggedIn
{
    if (![self hasUserLoggedIn]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kShelbyUserHasLoggedInKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }   
}

- (void)deleteDeviceToken:(NSString *)token
{
    if (token) {
        User *user = [User currentAuthenticatedUserInContext:[self mainThreadContext]];
        if (user.token) {
            [ShelbyAPIClient deleteDeviceToken:token forUser:user andBlock:^(id JSON, NSError *error) {
                // Do Nothing
            }];
        }
    }
}

- (void)registerDeviceToken:(NSString *)token
{
    if (token) {
        User *user = [User currentAuthenticatedUserInContext:[self mainThreadContext]];
        if (user.token) {
            [ShelbyAPIClient postDeviceToken:token forUser:user andBlock:^(id JSON, NSError *error) {
                // Do Nothing
            }];
        }
    }
}

- (void)userAskForFacebookPublishPermissions
{
    [self openFacebookSessionWithAllowLoginUI:NO andAskPublishPermissions:YES];
}

- (void)openFacebookSessionWithAllowLoginUI:(BOOL)allowLoginUI
{
    [self openFacebookSessionWithAllowLoginUI:allowLoginUI andAskPublishPermissions:NO];
}

- (void)inviteFacebookFriends
{
    [[FacebookHandler sharedInstance] sendAppRequest];
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
            if (user) {
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
                                                    NSString *errorMessage = nil;
                                                    if ([error.domain isEqualToString:@"ShelbyAPIClient"] && error.code == 403002) {
                                                        NSDictionary *errorInfo = error.userInfo;
                                                        errorMessage = [self errorMessageForExistingAccountWithErrorDictionary:errorInfo];
                                                    }
                                                    //did NOT add this auth to the current user
                                                    [self.delegate facebookConnectDidCompleteWithError:errorMessage];
                                                    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookAuthorizationCompletedWithError object:nil];
                                                    [self cleanupSession];
                                                }
                                            }];
            } else {
                [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNotificationFacebookConnectCompleted object:facebookUser];
            }
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

- (void)postNotificationForError:(NSError *)error
{
    if ([ShelbyErrorUtility isConnectionError:error]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyNoInternetConnectionNotification object:nil];
    }
}


// This is an error message when a user tries to login with a FB/TW account. But that FB/TW account does not belong to a Shelby user.
- (NSString *)errorMessageForExistingAccountWithErrorDictionary:(NSDictionary *)errorInfo
{
    NSString *existingUserNickname = errorInfo[@"existing_other_user_nickname"];
    return [NSString stringWithFormat:NSLocalizedString(@"ALREADY_LOGGED_IN_MESSAGE", nil), existingUserNickname];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if ( _managedObjectModel ) {
        return _managedObjectModel;
    }
    _managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return _managedObjectModel;
}

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

    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    //djs NB: IF you crash when updating CoreData, next run you can get an EXC_BAD_ACCESS on the following line
    if ( ![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error] )
    {
        // Delete datastore if there's a conflict. User can re-login to repopulate the datastore.
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
    if (_mainContextObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_mainContextObserver];
    }
    self.mainThreadMOC = nil;
    if (_privateContextObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_privateContextObserver];
    }
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
    _privateContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_privateContext queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self.mainThreadMOC mergeChangesFromContextDidSaveNotification:note];
    }];
    _mainContextObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:_mainThreadMOC queue:nil usingBlock:^(NSNotification *note) {
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
    
    //current user for following calculations
    User *currentUser = [User currentAuthenticatedUserInContext:context forceRefresh:NO];
    
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

                    id following = [roll objectForKey:@"following"];
                    if (currentUser && following && [following respondsToSelector:@selector(boolValue)]) {
                        if ([following boolValue]) {
                            [currentUser didFollowRoll:channel.roll.rollID];
                        } else {
                            [currentUser didUnfollowRoll:channel.roll.rollID];
                        }
                    }
                    
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
    NSDictionary *frameDictArray = jsonDict[@"result"];
    
    if(![frameDictArray isKindOfClass:[NSDictionary class]]){
        return nil;
    }
    
    NSArray *frames = frameDictArray[@"frames"];
    if (![frames isKindOfClass:[NSArray class]]){
        return nil;
    }

    NSMutableArray *resultFrames = [@[] mutableCopy];
    
    for (NSDictionary *frameDict in frames) {
        if(![frameDict isKindOfClass:[NSDictionary class]]){
            continue;
        }

        Frame *f = [Frame frameForDictionary:frameDict requireCreator:NO inContext:context];
        STVDebugAssert(f.roll == roll, @"roll should have been found & set");
 
        if (f) {
            [resultFrames addObject:f];
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
