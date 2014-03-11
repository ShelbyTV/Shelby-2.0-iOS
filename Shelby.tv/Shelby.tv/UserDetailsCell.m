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
    self.avatar.layer.cornerRadius = self.avatar.bounds.size.width/2.f;
    self.avatar.layer.masksToBounds = YES;
    
    self.name.font = kShelbyBodyFont1;
    self.userName.font = kShelbyBodyFont2Bold;
    self.email.font = kShelbyBodyFont2Bold;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
