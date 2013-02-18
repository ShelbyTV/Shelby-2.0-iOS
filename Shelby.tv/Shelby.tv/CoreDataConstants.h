//
//  kShelbyCoreDataConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "Channel.h"
#import "Conversation.h"
#import "Creator.h"
#import "Frame.h"
#import "Messages.h"
#import "Stream.h"
#import "Roll.h"
#import "User.h"
#import "Video.h"

// Entity Constants
#define kShelbyCoreDataEntityChannel                    @"Channel"
#define kShelbyCoreDataEntityConversation               @"Conversation"
#define kShelbyCoreDataEntityCreator                    @"Creator"
#define kShelbyCoreDataEntityFrame                      @"Frame"
#define kShelbyCoreDataEntityMessages                   @"Messages"
#define kShelbyCoreDataEntityRoll                       @"Roll"
#define kShelbyCoreDataEntityStream                     @"Stream"
#define kShelbyCoreDataEntityUser                       @"User"
#define kShelbyCoreDataEntityVideo                      @"Video"

// Channe; Attribute Constants
#define kShelbyCoreDataChannelID                        @"channelID"
#define kShelbyCoreDataChannelDisplayTitle              @"displayTitle"
#define kShelbyCoreDataChannelDisplayDescription        @"displayDescription"
#define kShelbyCoreDataChannelDisplayThumbnailURL       @"displayThumbnailURL"


// Conversation Attribute Constants
#define kShelbyCoreDataConversationID                   @"conversationID"
#define kShelbyCoreDataConversationMessageCount         @"messageCount"

// Creator Attribute Constants
#define kShelbyCoreDataCreatorID                        @"creatorID"
#define kShelbyCoreDataCreatorNickname                  @"nickname"
#define kShelbyCoreDataCreatorUserImage                 @"userImage"

// Frame Attribute Constants
#define kShelbyCoreDataFrameID                          @"frameID"
#define kShelbyCoreDataFrameChannelID                   @"channelID"
#define kShelbyCoreDataFrameConversationID              @"conversationID"
#define kShelbyCoreDataFrameCreatedAt                   @"createdAt"
#define kShelbyCoreDataFrameCreatorID                   @"creatorID"
#define kShelbyCoreDataFrameIsSynced                    @"isSynced"
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

// Stream Attribute Constants
#define kShelbyCoreDataStreamID                         @"streamID"
#define kShelbyCoreDataStreamTimestamp                  @"timestamp"

// User Attribute Constants
#define kShelbyCoreDataUserID                           @"userID"
#define kShelbyCoreDataUserAdmin                        @"admin"
#define kShelbyCoreDataUserNickname                     @"nickname"
#define kShelbyCoreDataUserPersonalRollID               @"personalRollID"
#define kShelbyCoreDataUserLikesRollID                  @"likesRollID"
#define kShelbyCoreDataUserToken                        @"token"
#define kShelbyCoreDataUserImage                        @"userImage"

// Video Attribute Constants
#define kShelbyCoreDataVideoID                          @"videoID"
#define kShelbyCoreDataVideoCaption                     @"caption"
#define kShelbyCoreDataVideoExtractedURL                @"extractedURL"
#define kShelbyCoreDataVideoProviderName                @"providerName"
#define kShelbyCoreDataVideoProviderID                  @"providerID"
#define kShelbyCoreDataVideoTitle                       @"title"
#define kShelbyCoreDataVideoThumbnailURL                @"thumbnailURL"
