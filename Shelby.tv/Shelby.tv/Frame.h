//
//  Frame.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Conversation, DashboardEntry, Roll, User, Video;

@interface Frame : NSManagedObject

@property (nonatomic, retain) NSString * channelID;
@property (nonatomic, retain) NSString * conversationID;
@property (nonatomic, retain) NSString * createdAt;
@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * frameID;
@property (nonatomic, retain) NSNumber * isStoredForLoggedOutUser;
@property (nonatomic, retain) NSNumber * isSynced;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * videoID;
@property (nonatomic, retain) Conversation *conversation;
@property (nonatomic, retain) User *creator;
@property (nonatomic, retain) DashboardEntry *dashboardEntry;
@property (nonatomic, retain) Roll *roll;
@property (nonatomic, retain) Video *video;

@end
