//
//  SPCategoryPeekView.m
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPCategoryPeekView.h"
@interface SPCategoryPeekView()
@property (nonatomic) UILabel *title;
@end


@implementation SPCategoryPeekView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _title = [[UILabel alloc] initWithFrame:CGRectMake(kShelbySPVideoWidth / 2 - 200, 10, 400, 40)];
    }
    return self;
}

- (void)setupWithCategoryDisplay:(SPCategoryDisplay *)categoryDisplay;
{
    [self.title setTextAlignment:NSTextAlignmentCenter];
    [self.title setText:[categoryDisplay categoryDisplayTitle]];
    [self.title setTextColor:[UIColor whiteColor]];
    [self.title setFont:[UIFont fontWithName:@"Helvetica-Bold" size:28.0]];
    [self.title setBackgroundColor:[UIColor clearColor]];
    
    [self addSubview:self.title];
    [self setBackgroundColor:[categoryDisplay categoryDisplayColor]];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.title setFrame:CGRectMake(kShelbySPVideoWidth / 2 - 200, frame.size.height / 2 - 20, self.title.frame.size.width, self.title.frame.size.height)];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
