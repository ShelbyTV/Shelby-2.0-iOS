//
//  VideoPlayerThumbnailOverlayView.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/31/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Video.h"

@interface VideoPlayerThumbnailOverlayView : UIView

@property (nonatomic, strong) Video *video;

- (void)showSpinner:(BOOL)spinnerInsteadOfPlay;

@end
