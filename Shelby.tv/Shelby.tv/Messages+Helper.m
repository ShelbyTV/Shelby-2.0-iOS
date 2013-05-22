//
//  Messages+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Messages+Helper.h"
#import "NSObject+NullHelper.h"

NSString * const kShelbyCoreDataEntityMessages = @"Messages";

@implementation Messages (Helper)

+ (Messages *)messageForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    //look for existing Message
    NSString *messageID = dict[@"id"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:kShelbyCoreDataEntityMessages];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"messageID == %@", messageID];
    request.predicate = pred;
    request.fetchLimit = 1;
    NSError *error;
    NSArray *fetchedMessages = [context executeFetchRequest:request error:&error];
    if(error || !fetchedMessages){
        return nil;
    }
    
    Messages *message = nil;
    if([fetchedMessages count] == 1){
        message = fetchedMessages[0];
    } else {
        message = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityMessages
                                                inManagedObjectContext:context];
        message.messageID = messageID;
        message.nickname = dict[@"nickname"];
        message.text = dict[@"text"];
        message.userImage = [dict[@"user_image_url"] nilOrSelfWhenNotNull];
        message.createdAt = dict[@"created_at"];
        message.originNetwork = [dict[@"origin_network"] nilOrSelfWhenNotNull];
    }
    
    return message;
}

@end
