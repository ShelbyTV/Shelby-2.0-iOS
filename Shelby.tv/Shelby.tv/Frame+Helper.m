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
