//
//  SettingsViewCell.m
//  Shelby.tv
//
//  Created by Keren on 7/31/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SettingsViewCell.h"

@interface SettingsViewCell()
@end

@implementation SettingsViewCell

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
    self.mainTitle.font = kShelbyBodyFont1;
    self.secondaryTitle.font = kShelbyBodyFont2Bold;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
