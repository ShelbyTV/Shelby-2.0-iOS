//
//  NSDate+DateFromBSONString.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 5/24/12.
//  Copyright (c) 2012 Shelby.tv. All rights reserved.
//

#import "NSDate+DateFromBSONString.h"

@implementation NSDate (DateFromBSONString)

+ (NSDate*)dataFromBSONstring:(NSString *)string
{
    unsigned long long result;
    [[NSScanner scannerWithString:[string substringToIndex:8]] scanHexLongLong:&result];
    return [[NSDate alloc] initWithTimeIntervalSince1970:result];
}

@end