//
//  SignupUserInfoCell.m
//  Shelby.tv
//
//  Created by Keren on 7/10/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupUserInfoCell.h"

@interface SignupUserInfoCell()
- (IBAction)assignAvatar:(id)sender;
@property (nonatomic, weak) IBOutlet UILabel *nameCopyLabel;
@end

@implementation SignupUserInfoCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    self.nameCopyLabel.font = kShelbyFontH3;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (IBAction)assignAvatar:(id)sender
{
    [self.delegate assignAvatar];
}

-(void)setName:(NSString *)name
{
    _name = name;
    self.nameCopyLabel.text = [NSString stringWithFormat:@"%@, let's start your stream off right.", _name];
}

@end
