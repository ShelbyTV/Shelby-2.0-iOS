//
//  Frame.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, Creator, Roll, Stream, Video;

@interface Frame : NSManagedObject

@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * frameID;
@property (nonatomic, retain) NSNumber * isSynced;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) Creator *creator;
@property (nonatomic, retain) Roll *roll;
@property (nonatomic, retain) NSSet *stream;
@property (nonatomic, retain) Video *video;
@end

@interface Frame (CoreDataGeneratedAccessors)

- (void)addStreamObject:(Stream *)value;
- (void)removeStreamObject:(Stream *)value;
- (void)addStream:(NSSet *)values;
- (void)removeStream:(NSSet *)values;

@end
