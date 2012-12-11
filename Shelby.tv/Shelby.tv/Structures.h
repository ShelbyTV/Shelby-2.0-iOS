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
    
    DataRequestType_Fetch = 0,          // Fetch NSManagedObjects or NSManagedObjectContext
    DataRequestType_StoreUser,          // Store User
    DataRequestType_BackgroundUpdate,   // Store data from background API poller
    DataRequestType_ActionUpdate,       // Store data from user action (e.g., when user scrolls far in stream)
    DataRequestType_VideoExtracted      // Store video data from results of SPVideoExtractor
    
} DataRequestType;

typedef enum _CategoryType
{
    
    CategoryType_Unknown = 0,
    CategoryType_Stream,
    CategoryType_QueueRoll,
    CategoryType_PersonalRoll
    
} CategoryType;

typedef enum _VideoProvider
{
    
    VideoProvider_None = 0,
    VideoProvider_YouTube,
    VideoProvider_Vimeo,
    VideoProvider_DailyMotion
    
} VideoProvider;