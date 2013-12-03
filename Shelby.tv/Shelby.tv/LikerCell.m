//
//  LikerCell.m
//  Shelby.tv
//
//  Created by Keren on 12/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "LikerCell.h"
@implementation LikerCell

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

- (IBAction)toggleFollow:(id)sender
{
    [self.delegate toggleFollowForUser:self.user];
}

@end
