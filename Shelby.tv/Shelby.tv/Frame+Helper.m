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
#import "ShelbyDataMediator.h"
#import "User+Helper.h"
#import "Video+Helper.h"

NSString * const kShelbyCoreDataEntityFrame = @"Frame";
NSString * const kShelbyCoreDataEntityFrameIDPredicate = @"frameID == %@";

NSString * const kShelbyFrameLongLink = @"http://shelby.tv/video/%@/%@/?frame_id=%@";

@implementation Frame (Helper)

@dynamic duplicateOf;
@dynamic duplicates;

+ (Frame *)frameForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
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
        NSDictionary *videoDict = dict[@"video"];
        if([videoDict isKindOfClass:[NSDictionary class]]){
            frame.video = [Video videoForDictionary:videoDict inContext:context];
        }
        NSDictionary *rollDict = dict[@"roll"];
        if([rollDict isKindOfClass:[NSDictionary class]]){
            frame.roll = [Roll rollForDictionary:rollDict inContext:context];
        }
    }
    
    NSDictionary *creatorDict = dict[@"creator"];
    if([creatorDict isKindOfClass:[NSDictionary class]]){
        frame.creator = [User userForDictionary:creatorDict inContext:context];
    }
    if (!frame.creator) {
        [context deleteObject:frame];
        return nil;
    }
    
    NSDictionary *conversationDict = dict[@"conversation"];
    if([conversationDict isKindOfClass:[NSDictionary class]]){
        frame.conversation = [Conversation conversationForDictionary:conversationDict inContext:context];
    }
    
    return frame;
}

+ (NSArray *)framesForRoll:(Roll *)roll
                 inContext:(NSManagedObjectContext *)moc
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *framesInRoll = [NSPredicate predicateWithFormat:@"rollID == %@ && clientUnliked == NO", roll];
    request.predicate = framesInRoll;
    //Mongo IDs are prefixed with timestamp, so this gives us reverse-chron
    NSSortDescriptor *sortById = [NSSortDescriptor sortDescriptorWithKey:@"frameID" ascending:NO];
    request.sortDescriptors = @[sortById];
    
    NSError *err;
    NSArray *results = [moc executeFetchRequest:request error:&err];
    STVAssert(!err, @"couldn't fetch frames on roll!");
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
    Frame *currentFrame;
    if ([entity isKindOfClass:[Frame class]]) {
        currentFrame = (Frame *)entity;
    } else if ([entity isKindOfClass:[DashboardEntry class]]) {
        currentFrame = ((DashboardEntry *)entity).frame;
    }
    STVAssert(currentFrame, @"expected entity to be a DashboardEntry or Frame");
    return currentFrame;
}

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle
{
    if(self.conversation && [self.conversation.messages count] > 0){
        // Grab only messages from the creator, use the oldest
        NSPredicate *creatorNickPredicate = [NSPredicate predicateWithFormat:@"nickname == %@", self.creator.nickname];
        NSSet *messagesFromCreator = [self.conversation.messages filteredSetUsingPredicate:creatorNickPredicate];
        if([messagesFromCreator count] > 0){
            NSSortDescriptor *createdAt = [NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES];
            NSArray *sortedMessagesFromCreator = [messagesFromCreator sortedArrayUsingDescriptors:@[createdAt]];
            return ((Messages *)sortedMessagesFromCreator[0]).text;
        }
    }
    
    if (canUseVideoTitle){
        return self.video.title;
    }
    
    return nil;
}

- (NSString *)originNetwork
{
    // TODO: this is not really working. (seems to not work when origin network comes from Shelby)
    // Also, right now grabbing whatever network is not nil. 
    // Grab origin network...
    if (self.conversation && [self.conversation.messages count] > 0) {
        NSSet *messages = self.conversation.messages;
        for (Messages *message in messages) {
            if (message.originNetwork) {
                return message.originNetwork;
            }
        }
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

- (NSString *)shelbyID
{
    return self.frameID;
}

- (Video *)containedVideo
{
    return self.video;
}

- (BOOL)toggleLike
{
    return [[ShelbyDataMediator sharedInstance] toggleLikeForFrame:self];
}

- (BOOL)videoIsLiked
{
    User *currentUser = [User currentAuthenticatedUserInContext:self.managedObjectContext];
    if (currentUser) {
        return [currentUser hasLikedVideoOfFrame:self] || [self.clientUnsyncedLike boolValue];
    }
    // FUTURE
    // We could query the DB for any frame with a matching videoID where clientUnsyncedLike==1, but that would require
    // an update to the UNLIKE logic, which I'm not doing right now.
    return [self.clientUnsyncedLike boolValue];
}

- (NSString *)longLink
{
    return [NSString stringWithFormat:kShelbyFrameLongLink, self.video.providerName, self.video.providerID, self.frameID];
}

@end
