//
//  DeviceUtilities.m
//  Shelby.tv
//
//  Created by Keren on 2/21/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "DeviceUtilities.h"
#include <sys/types.h>
#include <sys/sysctl.h>

@implementation DeviceUtilities

+ (NSString *)platform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (BOOL)isIpadMini1
{
    NSString *platform = [DeviceUtilities platform];
    if ([platform isEqualToString:@"iPad2,5"] || [platform isEqualToString:@"iPad2,6"] || [platform isEqualToString:@"iPad2,7"]) {
        return YES;
    }
    
    return NO;
}
@end
