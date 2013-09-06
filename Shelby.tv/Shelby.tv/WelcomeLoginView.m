//
//  WelcomeLoginView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeLoginView.h"

@interface WelcomeLoginView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@end

@implementation WelcomeLoginView

- (void)awakeFromNib
{
    self.titleLabel.font = kShelbyFontH2;
}

@end
