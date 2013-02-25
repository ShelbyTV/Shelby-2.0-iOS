//
//  SPVideoDownloader.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/25/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPVideoDownloader : NSObject

- (id)initWithVideoFrame:(Frame *)videoFrame;
- (void)downloadVideo;
- (void)deleteDownloadedVideo;
+ (void)emptyCache;

@end
