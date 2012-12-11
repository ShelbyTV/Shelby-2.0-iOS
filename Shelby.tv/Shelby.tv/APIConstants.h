//
//  APIConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

// API Calls
#define kAPIShelbyPostAuthorizeEmail        @"https://api.shelby.tv/v1/token?email=%@&password=%@"
#define kAPIShelbyGetStream                 @"https://api.shelby.tv/v1/dashboard?auth_token=%@"
#define kAPIShelbyGetMoreStream             @"https://api.shelby.tv/v1/dashboard?auth_token=%@&skip=%@&limit=20"
#define kAPIShelbyGetRollFrames             @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@"
#define kAPIShelbyGetMoreRollFrames         @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@&skip=%@&limit=20"