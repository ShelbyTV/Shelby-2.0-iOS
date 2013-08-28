//
//  PointObject.h
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PointObject : NSObject
@property (nonatomic, assign) CGPoint point;
@property (nonatomic, assign) BOOL on;

- (id)initWithPoint:(CGPoint)point;

@end
