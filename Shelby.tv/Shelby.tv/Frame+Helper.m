//
//  Frame+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"

#import "Conversation+Helper.h"
#import "DashboardEntry+Helper.h"
#import "Messages+Helper.h"
#import "NSManagedObject+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyAnalyticsClient.h"
#import "ShelbyDataMediator.h"
#import "User+Helper.h"
#import "Video+Helper.h"

NSString * const kShelbyCoreDataEntityFrame = @"Frame";
NSString * const kShelbyCoreDataEntityFrameIDPredicate = @"frameID == %@";

NSString * const kShelbyFrameLongLink = @"http://shelby.tv/video/%@/%@/?frame_id=%@";

//KVO
NSString * const kFramePathClientLikedAt = @"clientLikedAt";
NSString * const kFramePathUpvoters = @"upvoters";

@implementation Frame (Helper)

@dynamic duplicateOf;
@dynamic duplicates;

+ (Frame *)frameForDictionary:(NSDictionary *)dict requireCreator:(BOOL)mustHaveCreator inContext:(NSManagedObjectContext *)context
{
    NSString *frameID = dict[@"id"];
    Frame *frame = [self fetchOneEntityNamed:kShelbyCoreDataEntityFrame
                             withIDPredicate:kShelbyCoreDataEntityFrameIDPredicate
                                       andID:frameID
                                   inContext:context];
    
    if (!frame) {
        frame = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityFrame
                                              inManagedObjectContext:context];
        frame.frameID = frameID;
        frame.createdAt = dict[@"created_at"];
    }
    
    NSDictionary *videoDict = dict[@"video"];
    if([videoDict isKindOfClass:[NSDictionary class]]){
        frame.video = [Video videoForDictionary:videoDict inContext:context];
    }
    
    NSDictionary *rollDict = dict[@"roll"];
    if([rollDict isKindOfClass:[NSDictionary class]]){
        frame.roll = [Roll rollForDictionary:rollDict inContext:context];
    }
    
    NSString *frameType = dict[@"frame_type"];
    frame.frameType = @(frameType ? [frameType intValue] : FrameTypeHeavyWeight);
    
    NSDictionary *creatorDict = dict[@"creator"];
    if([creatorDict isKindOfClass:[NSDictionary class]]){
        frame.creator = [User userForDictionary:creatorDict inContext:context];
    }
    if (mustHaveCreator && !frame.creator) {
        //only delete if it's brand new, somebody else created this for good reason
        if (frame.objectID.isTemporaryID) {
            [context deleteObject:frame];
        }
        return nil;
    }
    
    NSDictionary *conversationDict = dict[@"conversation"];
    if([conversationDict isKindOfClass:[NSDictionary class]]){
        frame.conversation = [Conversation conversationForDictionary:conversationDict inContext:context];
    }
    
    NSArray *upvoters = dict[@"upvoters"];
    if ([upvoters isKindOfClass:[NSArray class]] && [upvoters count] > 0) {
        for (NSString *upvoterId in upvoters) {
            //returns User if they exist, otherwise fetches and return async
            [[ShelbyDataMediator sharedInstance] fetchUserWithID:upvoterId inContext:context completion:^(User *upvoteUser) {
                if (upvoteUser) {
                    Frame *localFrame = (Frame *)[context objectWithID:frame.objectID];
                    //frame should have been saved by now.  If not, it may have been deleted b/c it was
                    //invalid (per business logic).  In which case, we should abort.
                    if (localFrame.objectID.isTemporaryID) {
                        return;
                    }
                    [localFrame addUpvotersObject:upvoteUser];
                    STVAssert(localFrame.upvoters, @"expected upvoters array to exist now");
                } else {
                    DLog(@"upvoteUser fetched failed for userID %@", upvoterId);
                }
            }];
        }
    }
    
    return frame;
}

+ (NSArray *)framesForRoll:(Roll *)roll
                 inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    request.fetchBatchSize = 10;
    NSPredicate *framesInRoll = [NSPredicate predicateWithFormat:@"rollID == %@ && clientUnliked == NO", roll];
    request.predicate = framesInRoll;
    //Mongo IDs are prefixed with timestamp, so this gives us reverse-chron
    NSSortDescriptor *sortById = [NSSortDescriptor sortDescriptorWithKey:@"frameID" ascending:NO];
    request.sortDescriptors = @[sortById];
    
    NSError *err;
    NSArray *results = [moc executeFetchRequest:request error:&err];
    STVDebugAssert(!err, @"couldn't fetch frames on roll!");
    if (err) {
        [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryIssues
                                              action:kAnalyticsIssueContextSaveError
                                               label:[NSString stringWithFormat:@"-[framesForRoll:inContext:] error: %@", err]];
    }
    return results;
}

+ (NSArray *)fetchAllLikesInContext:(NSManagedObjectContext *)context
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *likesPredicate = [NSPredicate predicateWithFormat:@"self.clientUnsyncedLike == %@", @1];
    request.predicate = likesPredicate;
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientLikedAt" ascending:NO];
    [request setSortDescriptors:@[sortDescriptor]];

    return [context executeFetchRequest:request error:nil];
}

+ (BOOL)doesFrameWithVideoID:(NSString *)videoID
           existOnRollWithID:(NSString *)rollID
                   inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *videoIDPredicate = [NSPredicate predicateWithFormat:@"self.roll.rollID == %@ AND self.video.videoID == %@", rollID, videoID];
    request.predicate = videoIDPredicate;
    request.fetchLimit = 1;
    
    NSError *error;
    NSUInteger count = [moc countForFetchRequest:request error:&error];
    return !error && count;
}

+ (BOOL)doesLikedFrameWithVideoID:(NSString *)videoID
                existOnRollWithID:(NSString *)rollID
                        inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *likedVideoIDPredicate = [NSPredicate predicateWithFormat:@"self.roll.rollID == %@ AND self.video.videoID == %@ AND self.clientUnliked != %@", rollID, videoID, @1];
    request.predicate = likedVideoIDPredicate;
    request.fetchLimit = 1;
    
    NSError *error;
    NSUInteger count = [moc countForFetchRequest:request error:&error];
    return !error && count;
}

+ (Frame *)frameWithVideoID:(NSString *)videoID
               onRollWithID:(NSString *)rollID
                  inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *videoIDPredicate = [NSPredicate predicateWithFormat:@"self.roll.rollID == %@ AND self.video.videoID == %@", rollID, videoID];
    request.predicate = videoIDPredicate;
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *frames = [moc executeFetchRequest:request error:&error];
    if (!error && [frames count]) {
        return frames[0];
    }
    return nil;
}

+ (Frame *)frameForEntity:(id<ShelbyVideoContainer>)entity
{
    if (!entity) {
        return nil;
    }

    Frame *currentFrame;
    if ([entity isKindOfClass:[Frame class]]) {
        currentFrame = (Frame *)entity;
    } else if ([entity isKindOfClass:[DashboardEntry class]]) {
        currentFrame = ((DashboardEntry *)entity).frame;
        STVAssert(currentFrame, @"expected DashboardEntry (%@) to have a Frame", ((DashboardEntry *)entity).dashboardEntryID);
    }
    STVAssert(currentFrame, @"expected entity to be a DashboardEntry or Frame");
    return currentFrame;
}

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle
{
    if(self.conversation && [self.conversation.messages count] > 0){
        // Grab only messages from the creator, use the oldest
        NSPredicate *creatorNickPredicate = [NSPredicate predicateWithFormat:@"nickname == %@", self.creator.nickname];
        NSSet * messagesFromCreator = [self.conversation.messages filteredSetUsingPredicate:creatorNickPredicate];
        if ([messagesFromCreator count] == 0 && self.creator.twitterNickname) {
            creatorNickPredicate = [NSPredicate predicateWithFormat:@"nickname == %@", self.creator.twitterNickname];
            messagesFromCreator = [self.conversation.messages filteredSetUsingPredicate:creatorNickPredicate];
        }
        if ([messagesFromCreator count] == 0 && self.creator.facebookNickname) {
            creatorNickPredicate = [NSPredicate predicateWithFormat:@"nickname == %@", self.creator.facebookNickname];
            messagesFromCreator = [self.conversation.messages filteredSetUsingPredicate:creatorNickPredicate];
        }

        if([messagesFromCreator count] > 0){
            NSSortDescriptor *createdAt = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
            NSArray *sortedMessagesFromCreator = [messagesFromCreator sortedArrayUsingDescriptors:@[createdAt]];
            return ((Messages *)sortedMessagesFromCreator[0]).text;
        }
    }
    
    if (canUseVideoTitle && [self typeOfFrame] == FrameTypeHeavyWeight){
        return self.video.title;
    }
    
    return nil;
}

- (NSString *)originNetwork
{
    // If user_type == 1 show origin_network.
    // Otherwise, if there is originator, show that. And if no originator show nothing.
    if ([self.creator.userType isEqualToNumber:@1]) {
        if (self.conversation && [self.conversation.messages count] > 0) {
            NSSet *messages = self.conversation.messages;
            for (Messages *message in messages) {
                if (message.originNetwork) {
                    return message.originNetwork;
                }
            }
        }
    } else if (self.originatorNickname) {
        return self.originatorNickname;
    }
  
    return nil;
}

- (BOOL)isPlayable
{
    if (self.video) {
        return [self.video isPlayable];
    }
    
    return NO;
}

- (BOOL)isNotification
{
    return NO;
}

- (NSString *)shelbyID
{
    return self.frameID;
}

- (Video *)containedVideo
{
    return self.video;
}

- (BOOL)doLike
{
    return [[ShelbyDataMediator sharedInstance] likeFrame:self];
}

- (BOOL)doUnlike
{
    return [[ShelbyDataMediator sharedInstance] unlikeFrame:self];
}

- (BOOL)videoIsLikedBy:(User *)user
{
    if (user) {
        return [user hasLikedVideoOfFrame:self] || [self.clientUnsyncedLike boolValue];
    }
    // FUTURE
    // We could query the DB for any frame with a matching videoID where clientUnsyncedLike==1, but that would require
    // an update to the UNLIKE logic, which I'm not doing right now.
    return [self.clientUnsyncedLike boolValue];
}

- (BOOL)videoIsLikedByCurrentUser
{
    return [self videoIsLikedBy:[User currentAuthenticatedUserInContext:self.managedObjectContext]];
}

- (NSString *)longLink
{
    return [NSString stringWithFormat:kShelbyFrameLongLink, self.video.providerName, self.video.providerID, self.frameID];
}

- (FrameType)typeOfFrame
{
    if (!self.frameType) {
        return FrameTypeHeavyWeight;
    }
    
    switch ([self.frameType intValue]) {
        case 0:
            return FrameTypeHeavyWeight;
        case 1:
            return FrameTypeLightWeight;
        default:
            return FrameTypeHeavyWeight;
    }
}

@end
