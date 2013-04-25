//
//  GAIConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/18/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#define kGAICategoryBrowse           @"Browse Metrics"
    #define kGAIBrowseActionLaunchPlaylist          @"User did launch playlist"
#define kGAICategorySession          @"Session Metrics"
    #define kGAISessionActionLoginSuccess           @"User did login"
    #define kGAISessionActionSignupSuccess          @"User did sign up"
#define kGAICategoryShare            @"Share Metrics"
    #define kGAIShareActionShareButton              @"User did tap share button to %@"
    #define kGAIShareActionShareSuccess             @"User did successfully share to %@"
    #define kGAIShareActionRollSuccess              @"User did successfully roll video"
#define kGAICategoryVideoPlayer      @"Video Player Metrics"
    #define kGAIVideoPlayerActionPinch              @"Pinched video player, did close channel"
    #define kGAIVideoPlayerActionSwipeHorizontal    @"Swiped video player"
    #define kGAIVideoPlayerActionSwipeVertical      @"Swiped video player, did change channel"
    #define kGAIVideoPlayerActionSingleTap          @"Overlay toggled via single tap gesture"
    #define kGAIVideoPlayerActionDoubleTap          @"Playback toggled via double tap gesture"
    #define kGAIVideoPlayerActionPauseButton        @"Playback toggled via pause button"
    #define kGAIVideoPlayerActionPlayButton         @"Playback toggled via play button"
    #define kGAIVideoPlayerActionRestartButton      @"Playback toggled via restart button"
#define kGAICategoryVideoList        @"Video List Metrics"