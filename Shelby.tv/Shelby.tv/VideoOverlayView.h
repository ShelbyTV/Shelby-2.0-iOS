//
//  VideoOverlayView.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/13/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyVideoContainer.h"

@interface VideoOverlayView : UIView

@property (nonatomic, strong) id<ShelbyVideoContainer>currentEntity;

@end
