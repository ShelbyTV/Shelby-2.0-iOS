//
//  kShelbyCoreDataConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "Dashboard.h"
#import "DashboardEntry.h"
#import "Conversation.h"
#import "Creator.h"
#import "Frame.h"
#import "Messages.h"
#import "StreamEntry.h"
#import "Roll.h"
#import "User.h"
#import "Video.h"

// Entity Constants
#define kShelbyCoreDataEntityConversation               @"Conversation"
#define kShelbyCoreDataEntityCreator                    @"Creator"
#define kShelbyCoreDataEntityDashboard                  @"Dashboard"
#define kShelbyCoreDataEntityDashboardEntry             @"DashboardEntry"
#define kShelbyCoreDataEntityFrame                      @"Frame"
#define kShelbyCoreDataEntityMessages                   @"Messages"
#define kShelbyCoreDataEntityRoll                       @"Roll"
#define kShelbyCoreDataEntityStreamEntry                @"StreamEntry"
#define kShelbyCoreDataEntityUser                       @"User"
#define kShelbyCoreDataEntityVideo                      @"Video"

// Conversation Attribute Constants
#define kShelbyCoreDataConversationID                   @"conversationID"
#define kShelbyCoreDataConversationMessageCount         @"messageCount"

// Creator Attribute Constants
#define kShelbyCoreDataCreatorID                        @"creatorID"
#define kShelbyCoreDataCreatorNickname                  @"nickname"
#define kShelbyCoreDataCreatorUserImage                 @"userImage"

// Dashboard Attribute Constants
#define kShelbyCoreDataDashboardID                      @"dashboardID"
#define kShelbyCoreDataDashboardDisplayTitle            @"displayTitle"
#define kShelbyCoreDataDashboardDisplayColor            @"displayColor"
#define kShelbyCoreDataDashboardDisplayDescription      @"displayDescription"
#define kShelbyCoreDataDashboardDisplayThumbnailURL     @"displayThumbnailURL"
#define kShelbyCoreDataDashboardDisplayTag              @"displayTag"

// DashboardEntry Attribute Constants
#define kShelbyCoreDataDashboardEntryID                 @"dashboardEntryID"
#define kShelbyCoreDataDashboardEntryDashboardID        @"dashboardID"
#define kShelbyCoreDataDashboardEntryTimestamp          @"timestamp"

// Frame Attribute Constants
#define kShelbyCoreDataFrameID                          @"frameID"
#define kShelbyCoreDataFrameChannelID                   @"channelID"
#define kShelbyCoreDataFrameConversationID              @"conversationID"
#define kShelbyCoreDataFrameCreatedAt                   @"createdAt"
#define kShelbyCoreDataFrameCreatorID                   @"creatorID"
#define kShelbyCoreDataFrameIsSynced                    @"isSynced"
#define kShelbyCoreDataFrameIsStoredForLoggedOutUser    @"isStoredForLoggedOutUser"
#define kShelbyCoreDataFrameRollID                      @"rollID"
#define kShelbyCoreDataFrameTimestamp                   @"timestamp"
#define kShelbyCoreDataFrameVideoID                     @"videoID"

// Messages Attribute Constants
#define kShelbyCoreDataMessagesConversationID           @"conversationID"
#define kShelbyCoreDataMessagesCreatedAt                @"createdAt"
#define kShelbyCoreDataMessagesID                       @"messageID"
#define kShelbyCoreDataMessagesNickname                 @"nickname"
#define kShelbyCoreDataMessagesOriginNetwork            @"originNetwork"
#define kShelbyCoreDataMessagesText                     @"text"
#define kShelbyCoreDataMessagesTimestamp                @"timestamp"
#define kShelbyCoreDataMessagesUserImage                @"userImage"

// Roll Attribute Constants
#define kShelbyCoreDataRollID                           @"rollID"
#define kShelbyCoreDataRollCreatorID                    @"creatorID"
#define kShelbyCoreDataRollFrameCount                   @"frameCount"
#define kShelbyCoreDataRollThumbnailURL                 @"thumbnailURL"
#define kShelbyCoreDataRollTitle                        @"title"
#define kShelbyCoreDataRollIsCategory                   @"isCategory"
#define kShelbyCoreDataRollDisplayTitle                 @"displayTitle"
#define kShelbyCoreDataRollDisplayColor                 @"displayColor"
#define kShelbyCoreDataRollDisplayDescription           @"displayDescription"
#define kShelbyCoreDataRollDisplayThumbnailURL          @"displayThumbnailURL"
#define kShelbyCoreDataRollDisplayTag                   @"displayTag"

// StreamEntry Attribute Constants
#define kShelbyCoreDataStreamEntryID                    @"streamEntryID"
#define kShelbyCoreDataStreamEntryTimestamp             @"timestamp"

// User Attribute Constants
#define kShelbyCoreDataUserID                           @"userID"
#define kShelbyCoreDataUserAdmin                        @"admin"
#define kShelbyCoreDataUserFacebookConnected            @"facebookConnected"
#define kShelbyCoreDataUserImage                        @"userImage"
#define kShelbyCoreDataUserNickname                     @"nickname"
#define kShelbyCoreDataUserPersonalRollID               @"personalRollID"
#define kShelbyCoreDataUserLikesRollID                  @"likesRollID"
#define kShelbyCoreDataUserToken                        @"token"
#define kShelbyCoreDataUserTwitterConnected             @"twitterConnected"

// Video Attribute Constants
#define kShelbyCoreDataVideoID                          @"videoID"
#define kShelbyCoreDataVideoCaption                     @"caption"
#define kShelbyCoreDataVideoElapsedTime                 @"elapsedTime"
#define kShelbyCoreDataVideoExtractedURL                @"extractedURL"
#define kShelbyCoreDataVideoProviderName                @"providerName"
#define kShelbyCoreDataVideoProviderID                  @"providerID"
#define kShelbyCoreDataVideoTitle                       @"title"
#define kShelbyCoreDataVideoThumbnailURL                @"thumbnailURL"
#define kShelbyCoreDataVideoFirstUnplayable             @"firstUnplayable"
#define kShelbyCoreDataVideoLastUnplayable              @"lastUnplayable"