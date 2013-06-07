//
//  Frame.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "Frame.h"
#import "Conversation.h"
#import "DVREntry.h"
#import "DashboardEntry.h"
#import "Frame.h"
#import "Roll.h"
#import "User.h"
#import "Video.h"


@implementation Frame

@dynamic channelID;
@dynamic clientLikedAt;
@dynamic clientUnliked;
@dynamic clientUnsyncedLike;
@dynamic conversationID;
@dynamic createdAt;
@dynamic creatorID;
@dynamic frameID;
@dynamic isStoredForLoggedOutUser;
@dynamic rollID;
@dynamic timestamp;
@dynamic videoID;
@dynamic conversation;
@dynamic creator;
@dynamic dashboardEntry;
@dynamic duplicateOf;
@dynamic duplicates;
@dynamic dvrEntry;
@dynamic roll;
@dynamic video;

@end
