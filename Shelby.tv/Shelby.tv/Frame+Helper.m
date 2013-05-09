//
//  Frame+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"
#import "Conversation+Helper.h"
#import "Video+Helper.h"
#import "Roll+Helper.h"
#import "ShelbyDataMediator.h"
#import "User+Helper.h"

@implementation Frame (Helper)

+ (Frame *)frameForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing Frame
    NSString *frameID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityFrame];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"frameID == %@", frameID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedFrames = [context executeFetchRequest:request error:&error];
    if(error || !fetchedFrames){
        return nil;
    }
    
    Frame *frame = nil;
    if([fetchedFrames count] == 1){
        frame = fetchedFrames[0];
    } else {
        frame = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityFrame
                                              inManagedObjectContext:context];
        frame.frameID = frameID;
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
    NSDictionary *conversationDict = dict[@"conversation"];
    if([conversationDict isKindOfClass:[NSDictionary class]]){
        frame.conversation = [Conversation conversationForDictionary:conversationDict inContext:context];
    }
    
    return frame;
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

- (void)toggleLike
{
    [[ShelbyDataMediator sharedInstance] toggleLikeForFrame:self];
}

@end
