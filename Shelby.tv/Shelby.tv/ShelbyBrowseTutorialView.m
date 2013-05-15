//
//  ShelbyBrowseTutorialView.m
//  Shelby.tv
//
//  Created by Keren on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyBrowseTutorialView.h"
@interface ShelbyBrowseTutorialView()
@property (nonatomic, weak) IBOutlet UILabel *title;
@property (nonatomic, weak) IBOutlet UILabel *message;
@property (nonatomic, weak) IBOutlet UIButton *closeButton;
@end


@implementation ShelbyBrowseTutorialView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setupWithTitle:(NSString *)title message:(NSString *)message andCloseButtonText:(NSString *)closeButtonText
{
    self.title.text = title;
    self.message.text = message;
    [self.closeButton setTitle:closeButtonText forState:UIControlStateNormal];
}
@end
