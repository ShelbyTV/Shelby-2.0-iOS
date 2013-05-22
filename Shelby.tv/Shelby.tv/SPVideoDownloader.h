//
//  SPVideoDownloader.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/25/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Video+Helper.h"

@class SPVideoPlayer;

@interface SPVideoDownloader : NSObject

/// Instance Methods
- (id)initWithVideo:(Video *)video;
- (void)startDownloading;
- (void)deleteDownloadedVideo;

/// Class Methods
+ (void)deleteAllDownloadedVideos;
+ (BOOL)canVideoBeLoadedFromDisk:(NSString *)offlineURL;

@end
