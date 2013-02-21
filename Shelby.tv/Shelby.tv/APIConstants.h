//
//  APIConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

// API Calls

/// POST Authorization
#define kShelbyAPIPostAuthorizeEmail        @"https://api.shelby.tv/v1/token?email=%@&password=%@"

/// GET Stream
#define kShelbyAPIGetStream                 @"https://api.shelby.tv/v1/dashboard?auth_token=%@"
#define kShelbyAPIGetMoreStream             @"https://api.shelby.tv/v1/dashboard?auth_token=%@&skip=%@&limit=20"

/// GET Rolls
#define kShelbyAPIGetRollFrames             @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@"
#define kShelbyAPIGetMoreRollFrames         @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@&skip=%@&limit=20"
#define kShelbyAPIGetRollFramesForSync      @"https://api.shelby.tv/v1/roll/%@/frames?auth_token=%@&limit=%d"

/// GET Channels
#define kShelbyAPIGetAllChannels            @"http://api.shelby.tv/v1/roll/featured?segment=ipad_standard"
#define kShelbyAPIGetChannelDashbaord       @"https://api.shelby.tv/v1/user/%@/dashboard"
#define kShelbyAPIGetMoreChannelDashbaord   @"https://api.shelby.tv/v1/user/%@/dashboard&skip=%@&limit=20"

/// GET Shortlink
#define kShelbyAPIGetShortLink              @"http://api.shelby.tv/v1/frame/%@/short_link"
#define kShelbyAPIGetLongLink               @"http://shelby.tv/video/%@/%@/?frame_id=%@"
          
/// POST Liked Frame
#define kShelbyAPIPostFrameToLikes          @"https://api.shelby.tv/v1/frame/%@/add_to_watch_later?auth_token=%@"

/// POST Roll Frame
#define kShelbyAPIPostFrameToRoll           @"https://api.shelby.tv/v1/roll/%@/frames?frame_id=%@&auth_token=%@&text=%@"

/// POST Shared Frame
#define kShelbyAPIPostFrameToAllSocial      @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=twitter&destination[]=facebook&text=%@"
#define kShelbyAPIPostFrameToTwitter        @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=twitter&text=%@"
#define kShelbyAPIPostFrameToFacebook       @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=facebook&text=%@"
