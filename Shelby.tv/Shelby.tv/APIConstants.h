//
//  APIConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/25/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

// API Calls

/// Shelby Base URL
#define kShelbyAPIBaseURL                   @"https://api.shelby.tv/"

/// POST Authorization
#define kShelbyAPIPostLogin                 @"https://api.shelby.tv/v1/token?email=%@&password=%@"

/// PUT Google Analytics Client ID
#define kShelbyAPIPutGAClientId             @"v1/user/%@?auth_token=%@"

/// GET Stream
//#define kShelbyAPIGetStream                 @"https://api.shelby.tv/v1/dashboard?auth_token=%@"
//#define kShelbyAPIGetMoreStream             @"https://api.shelby.tv/v1/dashboard?auth_token=%@&skip=%@&limit=20"

/// PUT Video
#define kShelbyAPIPutUnplayableVideo        @"https://api.shelby.tv/v1/video/%@/unplayable?auth_token=%@"

/// GET Rolls
#define kShelbyAPIGetRollFrames             @"http://api.shelby.tv/v1/roll/%@/frames"
#define kShelbyAPIGetMoreRollFrames         @"http://api.shelby.tv/v1/roll/%@/frames?skip=%@&limit=20"
#define kShelbyAPIGetRollFramesForSync      @"http://api.shelby.tv/v1/roll/%@/frames?limit=%d"

/// GET Channels
#ifdef SHELBY_ENTERPRISE
    #define kShelbyAPIGetAllChannels                    @"http://api.shelby.tv/v1/roll/featured?segment=ipad_vertical_one"
#else
    #define kShelbyAPIGetAllChannels                    @"http://api.shelby.tv/v1/roll/featured?segment=ipad_standard"
#endif
#define kShelbyAPIGetChannelDashboardEntries        @"http://api.shelby.tv/v1/user/%@/dashboard"
#define kShelbyAPIGetChannelDashboardEntriesSince   @"http://api.shelby.tv/v1/user/%@/dashboard?since_id=%@"
#define kShelbyAPIGetMoreChannelDashboardEntries    @"http://api.shelby.tv/v1/user/%@/dashboard?skip=%@&limit=20"

/// GET Shortlink
#define kShelbyAPIGetShortLink              @"http://api.shelby.tv/v1/frame/%@/short_link"
#define kShelbyAPIGetLongLink               @"http://shelby.tv/video/%@/%@/?frame_id=%@"

/// POST Watched Frame
#define kShelbyAPIPostFrameToWatchedRoll    @"https://api.shelby.tv/v1/frame/%@/watched?auth_token=%@"

/// POST Liked Frame
#define kShelbyAPIPostFrameToLikesWithAuthentication            @"https://api.shelby.tv/v1/frame/%@/like?auth_token=%@"
#define kShelbyAPIPostFrameToLikesWithoutAuthentication         @"https://api.shelby.tv/v1/frame/%@/like"

/// POST Roll Frame
#define kShelbyAPIPostFrameToPersonalRoll   @"https://api.shelby.tv/v1/roll/%@/frames?frame_id=%@&auth_token=%@&text=%@"

/// POST Shared Frame
#define kShelbyAPIPostFrameToAllSocial      @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=twitter&destination[]=facebook&text=%@"
#define kShelbyAPIPostFrameToTwitter        @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=twitter&text=%@"
#define kShelbyAPIPostFrameToFacebook       @"https://api.shelby.tv/v1/frame/%@/share?auth_token=%@&destination[]=facebook&text=%@"

/// POST 3rd Party Token
#define kShelbyAPIPostThirdPartyToken           @"http://api.shelby.tv/v1/token?provider_name=%@&uid=%@&token=%@&secret=%@"
#define kShelbyAPIPostThirdPartyTokenNoSecret   @"http://api.shelby.tv/v1/token?provider_name=%@&uid=%@&token=%@"
