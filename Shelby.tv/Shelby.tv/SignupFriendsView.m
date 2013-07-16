//
//  SignupFriendsView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupFriendsView.h"

@interface SignupFriendsView()
@property (weak, nonatomic) IBOutlet UILabel *nameCopyLabel;
@property (weak, nonatomic) IBOutlet UISwitch *spamSwitch;
@end

// TODO: delete - not using this anymore - but leaving for now as we might change signup flow :-)
@implementation SignupFriendsView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(void)setName:(NSString *)name
{
    _name = name;
    self.nameCopyLabel.text = [NSString stringWithFormat:@"%@, you might be surprised by the videos your friends like ;-)", _name];
}

- (IBAction)spamSwitchChanged:(UISwitch *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No auto-posting, no SPAM!"
                                                    message:@"We don't do that sort of thing around here."
                                                   delegate:self
                                          cancelButtonTitle:@"Thank You"
                                          otherButtonTitles:nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.spamSwitch setOn:NO animated:YES];
}

@end
