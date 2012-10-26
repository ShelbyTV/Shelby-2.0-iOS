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
#import "Video.h"

// Entity Constants
#define kCoreDataEntityConversation                 @"Conversation"
#define kCoreDataEntityFrame                        @"Frame"
#define kCoreDataEntityMessages                     @"Messages"
#define kCoreDataEntityStream                       @"Stream"
#define kCoreDataEntityVideo                        @"Video"

// Relationship Constants
#define kCoreDataRelationshipConversation           @"conversation"
#define kCoreDataRelationshipStream                 @"stream"
#define kCoreDataRelationshipFrame                  @"frame"
#define kCoreDataRelationshipMessages               @"messages"
#define kCoreDataRelationshipVideo                  @"video"

// Conversation Attribute Constants
#define kCoreDataConversationID                     @"conversationID"
#define kCoreDataConversationMessageCount           @"messageCount"

// Stream Attribute Constants
#define kCoreDataStreamID                           @"streamID"
#define kCoreDataStreamTimestamp                    @"timestamp"

// Frame Attribute Constants
#define kCoreDataFrameConversationID                @"conversationID"
#define kCoreDataFrameCreatedAt                     @"createdAt"
#define kCoreDataFrameID                            @"frameID"
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

// Video Attribute Constants
#define kCoreDataVideoID                            @"videoID"
#define kCoreDataVideoCaption                       @"caption"
#define kCoreDataVideoProviderName                  @"providerName"
#define kCoreDataVideoProviderID                    @"providerID"
#define kCoreDataVideoSourceURL                     @"sourceURL"
#define kCoreDataVideoTitle                         @"title"
#define kCoreDataVideoThumbnailURL                  @"thumbnailURL"