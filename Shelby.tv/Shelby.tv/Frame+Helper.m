//
//  Frame+Helper.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 4/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"

@implementation Frame (Helper)

- (NSString *)creatorsInitialCommentWithFallback:(BOOL)canUseVideoTitle
{
    if(self.conversation && self.conversation.messageCount > 0){
        // Grab only messages from the creator, use the oldest
        CoreDataUtility *dataUtility = [[CoreDataUtility alloc] initWithRequestType:DataRequestType_Fetch];
        NSString *message = [dataUtility fetchTextFromFirstMessageInConversation:self.conversation];
        if (message) {
            return message;
        }
        //since we don't support conversations right now, this would work:
        //return ((Messages *)self.conversation.messages.anyObject).text;
    }
    
    if (canUseVideoTitle){
        return self.video.title;
    } else {
        return nil;
    }
}

@end
