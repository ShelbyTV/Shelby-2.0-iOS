//
//  APIConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

// API Calls
#define kShelbyAPIPostAuthorizeEmail        @"https://api.shelby.tv/v1/token?email=%@&password=%@"
#define kShelbyAPIGetStream                 @"https://api.shelby.tv/v1/dashboard?auth_token=%@"
#define kShelbyAPIGetMoreStream             @"https://api.shelby.tv/v1/dashboard?auth_token=%@&skip=%@&limit=20"
#define kShelbyAPIGetRollFrames             @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@"
#define kShelbyAPIGetMoreRollFrames         @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@&skip=%@&limit=20"
#define kShelbyAPIGetRollFramesForSync      @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@&limit=%d"
#define kShelbyAPIGetAllChannels            @"http://api.shelby.tv/v1/roll/featured?segment=ipad_standard"
#define kShelbyAPIGetChannelDashbaord       @"https://api.shelby.tv/v1/user/%@/dashboard"
