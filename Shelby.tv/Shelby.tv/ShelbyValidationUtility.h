//
//  ShelbyValidationUtility.h
//  Shelby.tv
//
//  Created by Keren on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShelbyValidationUtility : NSObject

+ (BOOL)isNameValid:(NSString *)name;
+ (BOOL)isEmailValid:(NSString *)email;
+ (BOOL)isUsernameValid:(NSString *)username;
+ (BOOL)isPasswordValid:(NSString *)password;

@end
