//
//  TopLevelNavigationCell.m
//  Shelby.tv
//
//  Created by Dan Spinosa on 1/20/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import "TopLevelNavigationCell.h"
#import "STVLabelWithMargins.h"

@interface TopLevelNavigationCell()
@property (weak, nonatomic) IBOutlet STVLabelWithMargins *badgeLabel;
@end

@implementation TopLevelNavigationCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    //notification badge visuals
    self.badgeLabel.backgroundColor = kShelbyColorGreen;
    self.badgeLabel.layer.cornerRadius = self.badgeLabel.bounds.size.height / 2.f;
    self.badgeLabel.margins = CGSizeMake(8.f, 0);
    self.badgeLabel.alpha = 0.f;
}

- (void)prepareForReuse
{
    [self setBadge:0];
}

- (void)setBadge:(NSUInteger)count
{
    if (count > 0) {
        self.badgeLabel.alpha = 1.f;
        self.badgeLabel.text = [NSString stringWithFormat:@"%i", count];
    } else {
        self.badgeLabel.alpha = 1.f;
        self.badgeLabel.text = nil;
    }
}

@end
