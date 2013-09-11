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
//djs pretty sure we don't need this "stored" date (i think it means when the extracted URL was stored)
//#define kShelbySPVideoPlayerStoredDate          @"SP Video Player Stored Date"
//djs let's just make this an instance variable on SPVideoPlayer
//#define kShelbySPVideoPlayerElapsedTime         @"SP Video Player Elapsed Time"
//djs extracted URL should always be retrieved from SPVideoExtractor (how simple is that!)
//#define kShelbySPVideoPlayerExtractedURL        @"SP Video Player Extracted URL"

/// Notification
//djs using blocks now,
//#define kShelbySPVideoExtracted                 @"SP Video Extracted"
//#define kShelbySPUserDidScrollToUpdate          @"SP User Did Scroll To Update"
//#define kShelbySPLoadVideoAfterUnplayableVideo  @"SP Load Video After Unplayable Video"
//#define kShelbySPUserDidSwipeToNextVideo        @"SP User Did Swipe To Next Video"

/// SPVideoPlayer
#define kShelbySPVideoBufferLikelyToKeepUp      @"playbackLikelyToKeepUp"
#define kShelbySPVideoBufferEmpty               @"playbackBufferEmpty"
#define kShelbySPLoadedTimeRanges               @"loadedTimeRanges"
#define kShelbySPAVPlayerDuration               @"duration"

/// SPVideoReel
#define kShelbySPCurrentVideo                   @"SP Current Video"

/// Video Player Size
#define kShelbySPVideoWidth                     [[UIScreen mainScreen] bounds].size.height
#define kShelbySPVideoHeight                    [[UIScreen mainScreen] bounds].size.width