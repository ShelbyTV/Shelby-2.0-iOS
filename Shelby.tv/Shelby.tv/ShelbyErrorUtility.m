//
//  ShelbyErrorUtility.m
//  Shelby.tv
//
//  Created by Keren on 9/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyErrorUtility.h"

NSString * const kShelbyNoInternetConnectionNotification = @"kShelbyNoInternetConnectionNotification";

@implementation ShelbyErrorUtility

+ (BOOL)isConnectionError:(NSError *)error
{
    // Error code -1009 - no connection
    // Error code -1001 - timeout
    if (error && (error.code == -1009 || error.code == -1001)) {
        return YES;
    }
    
    return NO;

}
@end
