//
//  SPShareRollView.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPShareRollView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *videoThumbnailView;
@property (weak, nonatomic) IBOutlet UITextView *rollTextView;
@property (weak, nonatomic) IBOutlet UIButton *twitterButton;
@property (weak, nonatomic) IBOutlet UIButton *facebookButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *rollButton;

@end
