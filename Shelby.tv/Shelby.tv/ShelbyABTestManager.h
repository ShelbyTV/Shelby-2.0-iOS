//
//  ShelbyABTestManager.h
//  Shelby.tv
//
//  Created by Keren on 9/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kShelbyABTestNotification;
extern NSString * const kShelbyABTestNotificationTime;
extern NSString * const kShelbyABTestNotificationDay;
extern NSString * const kShelbyABTestNotificationMessage;


@interface ShelbyABTestManager : NSObject

+ (ShelbyABTestManager *)sharedInstance;

- (void)startABTestManager;
- (NSDictionary *)activeBucketForTest:(NSString *)testName;
@end
