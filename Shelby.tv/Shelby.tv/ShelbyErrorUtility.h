//
//  ShelbyErrorUtility.h
//  Shelby.tv
//
//  Created by Keren on 9/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kShelbyNoInternetConnectionNotification;

@interface ShelbyErrorUtility : NSObject

+ (BOOL)isConnectionError:(NSError *)error;

@end
