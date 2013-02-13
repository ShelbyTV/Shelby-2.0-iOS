//
//  Conversation.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame, Messages;

@interface Conversation : NSManagedObject

@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSNumber * messageCount;
@property (nonatomic, retain) Frame *frame;
@property (nonatomic, retain) NSSet *messages;
@end

@interface Conversation (CoreDataGeneratedAccessors)

- (void)addMessagesObject:(Messages *)value;
- (void)removeMessagesObject:(Messages *)value;
- (void)addMessages:(NSSet *)values;
- (void)removeMessages:(NSSet *)values;

@end
