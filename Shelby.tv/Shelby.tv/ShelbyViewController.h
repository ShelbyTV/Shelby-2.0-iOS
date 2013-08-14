//
//  ShelbyViewController.h
//  Shelby.tv
//
//  Created by Keren on 5/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "GAITrackedViewController.h"
#import "ShelbyAnalyticsClient.h"

@interface ShelbyViewController : GAITrackedViewController

+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label;
+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
          withNicknameAsLabel:(BOOL)nicknameAsLabel;
+ (void)sendEventWithCategory:(NSString *)category
                   withAction:(NSString *)action
                    withLabel:(NSString *)label
                    withValue:(NSNumber *)value;

@end
