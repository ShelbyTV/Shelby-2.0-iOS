//
//  Conversation+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Conversation+Helper.h"

#import "Messages+Helper.h"
#import "NSManagedObject+Helper.h"

NSString * const kShelbyCoreDataEntityConversation = @"Conversation";
NSString * const kShelbyCoreDataEntityConversationIDPredicate = @"conversationID == %@";

@implementation Conversation (Helper)

+ (Conversation *)conversationForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing Conversation
    NSString *conversationID = dict[@"id"];
    Conversation *conversation = [self fetchOneEntityNamed:kShelbyCoreDataEntityConversation
                                           withIDPredicate:kShelbyCoreDataEntityConversationIDPredicate
                                                     andID:conversationID
                                                 inContext:context];

    if (!conversation) {
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
