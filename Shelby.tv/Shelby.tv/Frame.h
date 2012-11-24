//
//  Frame.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/23/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, Stream, Video;

@interface Frame : NSManagedObject

@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * frameID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) NSNumber * isSynced;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) NSSet *stream;
@property (nonatomic, retain) Video *video;
@end

@interface Frame (CoreDataGeneratedAccessors)

- (void)addStreamObject:(Stream *)value;
- (void)removeStreamObject:(Stream *)value;
- (void)addStream:(NSSet *)values;
- (void)removeStream:(NSSet *)values;

@end
