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
    APIRequestType_PostAuthorization,
    APIRequestType_GetStream,
    APIRequestType_GetQueue
    
} APIRequestType;

typedef enum _DataRequestType
{
    
    DataRequestType_None = 0,
    DataAPIRequestType_User,
    DataAPIRequestType_Stream,
    DataAPIRequestType_Queue
    
} DataRequestType;