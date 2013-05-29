//
//  Messages+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Messages+Helper.h"

#import "NSManagedObject+Helper.h"
#import "NSObject+NullHelper.h"

NSString * const kShelbyCoreDataEntityMessages = @"Messages";
NSString * const kShelbyCoreDataEntityMessagesIDPredicate = @"messageID == %@";

@implementation Messages (Helper)

+ (Messages *)messageForDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context
{
    NSString *messageID = dict[@"id"];
    Messages *message = [self fetchOneEntityNamed:kShelbyCoreDataEntityMessages
                                  withIDPredicate:kShelbyCoreDataEntityMessagesIDPredicate
                                            andID:messageID
                                        inContext:context];
    
    if (!message) {
        message = [NSEntityDescription insertNewObjectForEntityForName:kShelbyCoreDataEntityMessages
                                                inManagedObjectContext:context];
        message.messageID = messageID;
        message.nickname = dict[@"nickname"];
        message.text = [dict[@"text"] nilOrSelfWhenNotNull];
        message.userImage = [dict[@"user_image_url"] nilOrSelfWhenNotNull];
        message.createdAt = dict[@"created_at"];
        message.originNetwork = [dict[@"origin_network"] nilOrSelfWhenNotNull];
    }
    
    return message;
}

@end
