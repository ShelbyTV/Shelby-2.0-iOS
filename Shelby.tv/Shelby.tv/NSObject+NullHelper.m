//
//  NSObject+nilInsteadOfNull.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/22/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "NSObject+NullHelper.h"

@implementation NSObject (NullHelper)

- (id) nilOrSelfWhenNotNull
{
    return ((id)self == [NSNull null] ? nil : self);
}

@end
