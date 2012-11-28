//
//  Structures.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

typedef enum _APIRequestType
{
    
    APIRequestType_None = 0,
    APIRequestType_PostUserAuthorization,
    APIRequestType_GetStream,
    APIRequestType_GetRollFrames
    
} APIRequestType;

typedef enum _DataRequestType
{
    
    DataRequestType_None = 0,
    DataRequestType_User,
    DataRequestType_Stream,
    DataRequestType_QueueRoll,
    DataRequestType_PersonalRoll,
    DataRequestType_CategoryRoll
    
} DataRequestType;

typedef enum _VideoProvider
{
    
    VideoProvider_None = 0,
    VideoProvider_YouTube,
    VideoProvider_Vimeo,
    VideoProvider_DailyMotion
    
} VideoProvider;