//
//  kCoreDataConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import "Conversation.h"
#import "Frame.h"
#import "Messages.h"
#import "Stream.h"
#import "Roll.h"
#import "User.h"
#import "Video.h"

// Entity Constants
#define kCoreDataEntityConversation                 @"Conversation"
#define kCoreDataEntityFrame                        @"Frame"
#define kCoreDataEntityMessages                     @"Messages"
#define kCoreDataEntityRoll                         @"Roll"
#define kCoreDataEntityStream                       @"Stream"
#define kCoreDataEntityUser                         @"User"
#define kCoreDataEntityVideo                        @"Video"

// Conversation Attribute Constants
#define kCoreDataConversationID                     @"conversationID"
#define kCoreDataConversationMessageCount           @"messageCount"

// Frame Attribute Constants
#define kCoreDataFrameConversationID                @"conversationID"
#define kCoreDataFrameCreatedAt                     @"createdAt"
#define kCoreDataFrameID                            @"frameID"
#define kCoreDataFrameIsSynced                      @"isSynced"
#define kCoreDataFrameTimestamp                     @"timestamp"
#define kCoreDataFrameVideoID                       @"videoID"

// Messages Attribute Constants
#define kCoreDataMessagesConversationID             @"conversationID"
#define kCoreDataMessagesCreatedAt                  @"createdAt"
#define kCoreDataMessagesID                         @"messageID"
#define kCoreDataMessagesNickname                   @"nickname"
#define kCoreDataMessagesOriginNetwork              @"originNetwork"
#define kCoreDataMessagesText                       @"text"
#define kCoreDataMessagesTimestamp                  @"timestamp"
#define kCoreDataMessagesUserImage                  @"userImage"

// Roll Attribute Constants
#define kCoreDataRollID                             @"rollID"
#define kCoreDataRollCreatorID                      @"creatorID"
#define kCoreDataRollThumbnailURL                   @"thumbnailURL"
#define kCoreDataRollTitle                          @"title"

// Stream Attribute Constants
#define kCoreDataStreamID                           @"streamID"
#define kCoreDataStreamTimestamp                    @"timestamp"

// User Attribute Constants
#define kCoreDataUserID                             @"userID"
#define kCoreDataUserImage                          @"userImage"
#define kCoreDataUserToken                          @"token"
#define kCoreDataUserNickname                       @"nickname"
#define kCoreDataUserRollID                         @"rollID"
#define kCoreDataUserQueueID                        @"queueID"

// Video Attribute Constants
#define kCoreDataVideoID                            @"videoID"
#define kCoreDataVideoCaption                       @"caption"
#define kCoreDataVideoProviderName                  @"providerName"
#define kCoreDataVideoProviderID                    @"providerID"
#define kCoreDataVideoSourceURL                     @"sourceURL"
#define kCoreDataVideoTitle                         @"title"
#define kCoreDataVideoThumbnailURL                  @"thumbnailURL"