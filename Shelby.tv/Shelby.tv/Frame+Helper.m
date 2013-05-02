//
//  Frame+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"

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
        //djs TODO...
        //frame.video = [Video videoForDictionary:dict[@"video"] inContext:context];
        //frame.roll = [Roll rollForDictionary:dict[@"roll"] inContext:context];
    }
    
    //djs TODO...
    //frame.creator = [User userForDictionary:dict[@"creator"] inContext:context];
    //frame.conversation = [Conversation conversationForDictionary:dict[@"conversation"] inContext:context];
    
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

@end
