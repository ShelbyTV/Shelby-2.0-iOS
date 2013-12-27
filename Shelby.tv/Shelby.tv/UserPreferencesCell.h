//
//  UserPreferencesCell.h
//  Shelby.tv
//
//  Created by Keren on 12/27/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol UserPreferencesCellDelegate <NSObject>
- (void)toggleUserPreferences;
@end

@interface UserPreferencesCell : UITableViewCell
@property (nonatomic, strong) IBOutlet UILabel *preferenceText;
@property (nonatomic, strong) IBOutlet UISwitch *preferenceSwitch;
@property (nonatomic, weak) id<UserPreferencesCellDelegate> delegate;
@end
