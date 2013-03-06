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
    DataRequestType_StoreCategories,    // Store Categories
    DataRequestType_Sync,               // Sync with web
    DataRequestType_ActionUpdate,       // Store data from user action (e.g., when user scrolls far in video list)
    DataRequestType_VideoExtracted,     // Store video data from results of SPVideoExtractor
    DataRequestType_StoreVideoInCache   // Store video data in local cache
    
};

typedef NS_ENUM(NSUInteger, GroupType)
{
    
    GroupType_Stream,
    GroupType_Likes,
    GroupType_PersonalRoll,
    GroupType_CategoryChannel,
    GroupType_CategoryRoll
    
};

typedef NS_ENUM(NSUInteger, VideoProviderType)
{
    
    VideoProviderType_YouTube,
    VideoProviderType_Vimeo,
    VideoProviderType_DailyMotion
    
};
