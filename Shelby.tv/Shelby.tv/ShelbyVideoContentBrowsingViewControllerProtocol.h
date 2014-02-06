//
//  ShelbyVideoContentBrowsingViewControllerProtocol.h
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DisplayChannel.h"

extern NSString * const kShelbyRequestToShowCurrentlyOnNotification;

@protocol ShelbyVideoContentBrowsingViewControllerProtocol <NSObject>

- (DisplayChannel *)displayChannel;
- (NSArray *)singleVideoEntry;
- (void)scrollCurrentlyPlayingIntoView;

@end
