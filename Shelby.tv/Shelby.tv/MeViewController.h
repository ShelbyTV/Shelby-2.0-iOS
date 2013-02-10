//
//  MeViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoReel;

@interface MeViewController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIButton *likesButton;
@property (weak, nonatomic) IBOutlet UILabel *likesTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *likesDescriptionLabel;

@property (weak, nonatomic) IBOutlet UIButton *personalRollButton;
@property (weak, nonatomic) IBOutlet UILabel *personalRollTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *personalRollDescriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *personalRollUsernameLabel;

@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UILabel *streamTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *streamDescriptionLabel;

//@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)goButtonAction:(id)sender;

@end
