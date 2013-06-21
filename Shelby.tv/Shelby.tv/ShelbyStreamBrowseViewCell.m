//
//  ShelbyStreamBrowseViewCell.m
//  Shelby.tv
//
//  Created by Keren on 6/21/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewCell.h"

@interface ShelbyStreamBrowseViewCell()
@end

@implementation ShelbyStreamBrowseViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // KP KP: TODO: sizing is just to get an idea how it looks
    
    self.scrollView.contentSize = CGSizeMake(self.contentView.frame.size.width * 2 - 160, self.scrollView.frame.size.height);
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
