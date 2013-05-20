//
//  ShelbyVideoContainer.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/10/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//
//  Models may conform to this protocol to signal that they have access (directly or indirectly) to a Video model.
//  Currently implemented by DashboardEntry, Frame, Video.

#import <Foundation/Foundation.h>
#import "Video.h"

@protocol ShelbyVideoContainer <NSObject>

- (Video *)containedVideo;

@end
