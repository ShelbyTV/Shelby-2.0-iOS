//
//  SettingsViewController.h
//  Shelby.tv
//
//  Created by Keren on 4/24/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BrowseViewController.h"

@interface SettingsViewController : UIViewController <UIAlertViewDelegate>

@property (weak, nonatomic) BrowseViewController *parent;

- (void)logoutUser;
@end
