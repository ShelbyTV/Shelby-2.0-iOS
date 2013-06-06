//
//  TriageCell.m
//  Shelby.tv
//
//  Created by Keren on 6/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SPTriageCell.h"

@implementation SPTriageCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)prepareForReuse
{
    self.thumbnailImageView.image = nil;
    self.caption.backgroundColor = [UIColor whiteColor];
    [self unHighlightItem];
}

- (void)highlightItemWithColor:(UIColor *)color
{
    self.contentView.backgroundColor = color;
    self.caption.backgroundColor = color;
}

- (void)unHighlightItem
{
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.caption.backgroundColor = [UIColor whiteColor];
}

@end
