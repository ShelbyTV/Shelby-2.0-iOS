//
//  HeartView.m
//  Shelby.tv
//
//  Created by Keren on 8/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "HeartView.h"
#import "PointObject.h"

@interface HeartView()
@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) NSMutableArray *pointImageViews;
@property (nonatomic, strong) UIImageView *fullHeart;
@property (nonatomic, assign) CGFloat currentProgress;

@end

@implementation HeartView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _locations = [[NSArray alloc] initWithObjects:
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 0)],
                      [[PointObject alloc] initWithPoint:CGPointMake(20, 0)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 0)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 0)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 0)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 0)],
                      
                      [[PointObject alloc] initWithPoint:CGPointMake(8, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(12, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(52, 8)],
                      [[PointObject alloc] initWithPoint:CGPointMake(56, 8)],
                 
                      [[PointObject alloc] initWithPoint:CGPointMake(8, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(12, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(20, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(52, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(56, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(60, 16)],
                      [[PointObject alloc] initWithPoint:CGPointMake(64, 16)],

                      [[PointObject alloc] initWithPoint:CGPointMake(0, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(4, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(8, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(12, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(20, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(52, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(56, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(60, 24)],
                      [[PointObject alloc] initWithPoint:CGPointMake(64, 24)],

                      [[PointObject alloc] initWithPoint:CGPointMake(8, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(12, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(20, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(52, 32)],
                      [[PointObject alloc] initWithPoint:CGPointMake(56, 32)],
        
                      [[PointObject alloc] initWithPoint:CGPointMake(16, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(20, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(24, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(44, 40)],
                      [[PointObject alloc] initWithPoint:CGPointMake(48, 40)],

                      [[PointObject alloc] initWithPoint:CGPointMake(24, 48)],
                      [[PointObject alloc] initWithPoint:CGPointMake(28, 48)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 48)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 48)],
                      [[PointObject alloc] initWithPoint:CGPointMake(40, 48)],

                      [[PointObject alloc] initWithPoint:CGPointMake(28, 56)],
                      [[PointObject alloc] initWithPoint:CGPointMake(32, 56)],
                      [[PointObject alloc] initWithPoint:CGPointMake(36, 48)],

//                      [[PointObject alloc] initWithPoint:CGPointMake(32, 64)],
                      nil];
    }
    return self;
}

- (void)addPointsToView
{
    _fullHeart = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart-large.png"]];
    self.fullHeart.alpha = 0;
    [self addSubview:self.fullHeart];
    
    _pointImageViews = [[NSMutableArray alloc] initWithCapacity:[self.locations count]];
    
    NSInteger i = 0;
    for (PointObject *pointObject in self.locations) {
        UIImageView *heartDot = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"heart-dot.png"]];
        heartDot.frame = CGRectMake(pointObject.point.x, pointObject.point.y, heartDot.frame.size.width, heartDot.frame.size.height);
        heartDot.alpha = 0;
        self.pointImageViews[i] = heartDot;
        [self addSubview:heartDot];
        i++;
    }
}


- (void)setProgress:(CGFloat)progress
{
    NSInteger numberOfPoints = [self.locations count];
    
    NSInteger pointsToFill = ceil(numberOfPoints * (progress - _currentProgress));
    
    _currentProgress = progress;
    
    while (pointsToFill > 0) {
        NSInteger point = arc4random_uniform(numberOfPoints);
        PointObject *pointObject = self.locations[point];
        if (!pointObject.on) {
            pointObject.on = YES;
            ((UIImageView *)self.pointImageViews[point]).alpha = 1;
            pointsToFill--;
        }
    }
}

- (void)fillShape
{
    self.fullHeart.alpha = 1;
}

@end
