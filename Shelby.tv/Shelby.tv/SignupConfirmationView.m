//
//  SignupConfirmationView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "SignupConfirmationView.h"

@interface SignupConfirmationView()
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;
@end

#define kShelbySignupFlowViewYOriginEditMode -180

@implementation SignupConfirmationView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)setName:(NSString *)name
{
    _name = name;
    [self updateSummaryLabel];
}

-(void)setVideoTypes:(NSString *)videoTypes
{
    _videoTypes = videoTypes;
    [self updateSummaryLabel];
}

- (void)setSocialNetworksConnected:(NSString *)socialNetworksConnected
{
    _socialNetworksConnected = socialNetworksConnected;
    [self updateSummaryLabel];
}

- (void)updateSummaryLabel
{
    self.summaryLabel.text = [NSString stringWithFormat:@"%@, your stream is filling up!  Videos are coming from %@", self.name, self.videoTypes];
}

- (void)textFieldWillBeginEditing:(UITextField *)textField
{
    //move up so user can see our text fields
    [UIView animateWithDuration:0.2 animations:^{
        self.frame = CGRectMake(0, kShelbySignupFlowViewYOriginEditMode, self.frame.size.width, self.frame.size.height);
    }];
}

-(void)textFieldWillReturn:(UITextField *)textField
{
    //move back down
    [UIView animateWithDuration:0.2 animations:^{
        self.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    }];
}

@end
