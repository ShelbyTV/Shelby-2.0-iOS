//
//  ShelbyValidationUtility.m
//  Shelby.tv
//
//  Created by Keren on 1/21/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyValidationUtility.h"

@implementation ShelbyValidationUtility

#pragma mark - Validity Helpers

+ (BOOL)isNameValid:(NSString *)name
{
    NSString *trimmedName = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isValid = YES;
    
    //test length
    isValid &= [trimmedName length] > 1;
    
    return isValid;
}

+ (BOOL)isEmailValid:(NSString *)email
{
    NSString *trimmedEmail = [email stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isValid = YES;
    
    //test email regex
    static NSString *emailRegEx = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]+";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegEx];
    isValid &= [emailTest evaluateWithObject:trimmedEmail];
    
    return isValid;
}

+ (BOOL)isUsernameValid:(NSString *)username
{
    NSString *trimmedUsername = [username stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isValid = YES;
    
    //test length
    isValid &= [trimmedUsername length] > 1;
    
    return isValid;
}

+ (BOOL)isPasswordValid:(NSString *)password
{
    NSString *trimmedPassword = [password stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL isValid = YES;
    
    //test length
    isValid &= [trimmedPassword length] > 1;
    
    return isValid;
}

@end
