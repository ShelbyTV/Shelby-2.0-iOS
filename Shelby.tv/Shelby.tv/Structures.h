//
//  Structures.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

typedef NS_ENUM(NSUInteger, APIRequestType)
{
    
    APIRequestType_PostUserAuthorization,
    APIRequestType_GetStream,
    APIRequestType_GetRollFrames
    
};

typedef NS_ENUM(NSUInteger, DataRequestType)
{
    
    DataRequestType_Fetch,              // Fetch NSManagedObjects or NSManagedObjectContext
    DataRequestType_StoreUser,          // Store User
    DataRequestType_BackgroundUpdate,   // Store data from background API poller
    DataRequestType_Sync,               // Sync Core Data Objects with Web
    DataRequestType_ActionUpdate,       // Store data from user action (e.g., when user scrolls far in video list)
    DataRequestType_VideoExtracted,     // Store video data from results of SPVideoExtractor
    DataRequestType_StoreVideoInCache   // Store video data in local cache
    
};

typedef NS_ENUM(NSUInteger, CategoryType)
{
    
    CategoryType_Stream,
    CategoryType_Likes,
    CategoryType_PersonalRoll,
    CategoryType_CategoryChannel,
    CategoryType_CategoryRoll
    
};

typedef NS_ENUM(NSUInteger, VideoProviderType)
{
    
    VideoProviderType_YouTube,
    VideoProviderType_Vimeo,
    VideoProviderType_DailyMotion
    
};
