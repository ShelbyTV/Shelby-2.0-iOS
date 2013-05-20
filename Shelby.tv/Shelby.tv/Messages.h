//
//  Messages.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation;

@interface Messages : NSManagedObject

@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * messageID;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * originNetwork;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * userImage;
@property (nonatomic, retain) Conversation *conversation;

@end
