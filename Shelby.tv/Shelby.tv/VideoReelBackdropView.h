//
//  VideoReelBackdropView.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/16/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyVideoContainer.h"

@interface VideoReelBackdropView : UIView

@property (nonatomic, strong) id<ShelbyVideoContainer> backdropImageEntity;
@property (nonatomic, assign) BOOL showBackdropImage;

@end
