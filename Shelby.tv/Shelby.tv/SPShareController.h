//
//  SPShareController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoPlayer;

@interface SPShareController : NSObject

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer;

- (void)share;

@end
