//
//  ShelbyNavBarView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/9/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STVLabelWithMargins.h"

@interface ShelbyNavBarView : UIView

@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UIButton *sharesButton;
@property (weak, nonatomic) IBOutlet UIButton *communityButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *signupButton;
@property (weak, nonatomic) IBOutlet UIButton *notificationCenterButton;
@property (weak, nonatomic) IBOutlet STVLabelWithMargins *notificationLabel;
@property (assign, nonatomic) BOOL shouldHideNotificationLabel;

//our model, set to update display state
@property (weak, nonatomic) UIView *currentRow;

- (void)showLoggedInUserRows:(BOOL)showUserRows;

@end
