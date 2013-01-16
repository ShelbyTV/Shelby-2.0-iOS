//
//  MeViewController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/17/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

@class SPVideoReel;

@interface MeViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *streamButton;
@property (weak, nonatomic) IBOutlet UIButton *queueRollButton;
@property (weak, nonatomic) IBOutlet UIButton *personalRollButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;

- (void)dismissVideoReel:(SPVideoReel*)reel;

@end