//
//  UserPreferencesCell.m
//  Shelby.tv
//
//  Created by Keren on 12/27/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "UserPreferencesCell.h"
#import "DeviceUtilities.h"

@interface UserPreferencesCell()
- (IBAction)togglePreferences:(id)sender;
@end

@implementation UserPreferencesCell

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

- (void)awakeFromNib
{
    self.preferenceText.font = kShelbyBodyFont1;
}

- (IBAction)togglePreferences:(id)sender
{
    [self.delegate userEnabledPushNotification:self.preferenceSwitch.on];
}
@end
