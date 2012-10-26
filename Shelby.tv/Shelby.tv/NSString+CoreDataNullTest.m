//
//  NSString+CoreDataNullTest.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 5/16/12.
//  Copyright (c) 2012 Shelby.tv. All rights reserved.
//

#import "NSString+CoreDataNullTest.h"

@implementation NSString (CoreDataNullTest)

+ (NSString*)coreDataNullTest:(NSString*)string
{
    return [string isEqual:[NSNull null]] ? nil : string;
}

@end