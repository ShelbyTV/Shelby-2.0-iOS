//
//  UserDetailsCell.m
//  Shelby.tv
//
//  Created by Keren on 7/31/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "UserDetailsCell.h"
@interface UserDetailsCell()
@end

@implementation UserDetailsCell

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
    self.name.font = kShelbyFontH3;
    self.userName.font = kShelbyFontH4Medium;
    self.email.font = kShelbyFontH4Medium;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
