//
//  UIScreen+Resolution.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/8/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "UIScreen+Resolution.h"

@implementation UIScreen (Resolution)

- (BOOL)isRetinaDisplay
{
    
    static BOOL retina;
    static dispatch_once_t retinaToken;
    
	dispatch_once(&retinaToken, ^{
		retina = ([self respondsToSelector:@selector(scale)] && [self scale] == 2);
	});
    
	return retina;

}

@end
