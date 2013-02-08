//
//  UIScreen+Resolution.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/8/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "UIScreen+Resolution.h"

@implementation UIScreen (Resolution)

+ (BOOL)isRetina
{
    
    return [self respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0);

}

@end
