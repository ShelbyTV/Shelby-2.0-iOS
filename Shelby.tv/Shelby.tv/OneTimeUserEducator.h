//
//  OneTimeUserEducator.h
//  Shelby.tv
//
//  Created by Joshua Samberg on 2/27/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class User;

@interface OneTimeUserEducator : NSObject
+ (void)doOneTimeFollowingUserEducationForUser:(User *)user whenDidFollow:(BOOL)didFollow roll:(NSString *)rollID;
@end
