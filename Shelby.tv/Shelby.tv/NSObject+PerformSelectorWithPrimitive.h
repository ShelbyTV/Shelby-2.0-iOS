//
//  NSObject+PerformSelectorWithPrimitive.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/20/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PerformSelectorWithPrimitive)

- (id)performSelector:(SEL)aSelector withPrimitive:(void *)primitive afterDelay:(NSTimeInterval)delay;
- (id)performSelector:(SEL)aSelector withPrimitive:(void *)primitive1 withPrimitive:(void *)primitive2 afterDelay:(NSTimeInterval)delay;

@end
