//
//  PointObject.m
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "PointObject.h"
@interface PointObject()
@end

@implementation PointObject

- (id)initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self) {
        _point = point;
    }
    
    return self;
}

@end
