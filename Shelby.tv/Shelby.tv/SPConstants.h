//
//  SPConstants.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/27/12.
//  Copyright (c) 2012 Shelby TV. All rights reserved.
//

/// Custom Shelby Activities
#define kShelbySPActivityTypeRoll               @"tv.Shelby.Shelby-tv.roll"
#define kShelbySPActivityTypeLike               @"tv.Shelby.Shelby-tv.likes"

/// Temporary Video Cache
#define kShelbySPVideoPlayerStoredDate          @"SP Video Player Stored Date"
#define kShelbySPVideoPlayerElapsedTime         @"SP Video Player Elapsed Time"
#define kShelbySPVideoPlayerExtractedURL        @"SP Video Player Extracted URL"

/// Notification
#define kShelbySPVideoExtracted                 @"SP Video Extracted"
#define kShelbySPUserDidScrollToUpdate          @"SP User Did Scroll To Update"
#define kShelbySPLoadVideoAfterUnplayableVideo  @"SP Load Video After Unplayable Video"
#define kShelbySPUserDidSwipeToNextVideo        @"SP User Did Swipe To Next Video"

/// SPVideoPlayer
#define kShelbySPVideoBufferLikelyToKeepUp      @"playbackLikelyToKeepUp"
#define kShelbySPVideoBufferEmpty               @"playbackBufferEmpty"
#define kShelbySPLoadedTimeRanges               @"loadedTimeRanges"

/// SPVideoReel
#define kShelbySPCurrentVideo                   @"SP Current Video"

/// Video Player Size
#define kShelbySPVideoWidth                     [[UIScreen mainScreen] bounds].size.height
#define kShelbySPVideoHeight                    [[UIScreen mainScreen] bounds].size.width