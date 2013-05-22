//
//  ShelbyBrowseTutorialView.m
//  Shelby.tv
//
//  Created by Keren on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrowseTutorialView.h"

#import <QuartzCore/QuartzCore.h>

@interface ShelbyBrowseTutorialView()
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *message;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet UIView *tutorial;
@end


@implementation ShelbyBrowseTutorialView

- (id)initWithTitle:(NSString *)title message:(NSString *)message closeButtonText:(NSString *)closeButtonText andOwner:(UIViewController *)owner
{
    self = [[NSBundle mainBundle] loadNibNamed:@"ShelbyBrowseTutorialView" owner:owner options:nil][0];
    if (self) {
        _title.text = title;
        _message.text = message;
        [_closeButton setTitle:closeButtonText forState:UIControlStateNormal];

    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.tutorial.layer.borderColor = kShelbyColorTutorialGreen.CGColor;
    self.tutorial.layer.borderWidth = 5;
}

@end
