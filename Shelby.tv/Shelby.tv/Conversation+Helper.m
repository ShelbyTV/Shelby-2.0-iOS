//
//  Conversation+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Conversation+Helper.h"
#import "Messages+Helper.h"

@implementation Conversation (Helper)

+ (Conversation *)conversationForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing Conversation
    NSString *conversationID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityConversation];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"conversationID == %@", conversationID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedConversations = [context executeFetchRequest:request error:&error];
    if(error || !fetchedConversations){
        return nil;
    }
    
    Conversation *conversation = nil;
    if([fetchedConversations count] == 1){
        conversation = fetchedConversations[0];
    } else {
        conversation = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityConversation
                                                     inManagedObjectContext:context];
        conversation.conversationID = conversationID;
    }
    
    NSArray *messages = dict[@"messages"];
    if([messages isKindOfClass:[NSArray class]]){
        for (NSDictionary *messageDict in messages) {
            if([messageDict isKindOfClass:[NSDictionary class]]){
                Messages *message = [Messages messageForDictionary:messageDict inContext:context];
                if(message){
                    [conversation addMessagesObject:message];
                }
            }
        }
    }
    
    return conversation;
}

@end
