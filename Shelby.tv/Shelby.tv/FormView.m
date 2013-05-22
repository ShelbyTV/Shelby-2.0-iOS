//
//  FormView.m
//  Shelby.tv
//
//  Created by Keren on 3/14/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "FormView.h"

#import <QuartzCore/QuartzCore.h>

@interface FormView()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UIButton *goButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@end

@implementation FormView

- (void)awakeFromNib
{
    [[self.goButton titleLabel] setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.goButton.titleLabel.font.pointSize]];
    [[self.goButton titleLabel] setTextColor:kShelbyColorWhite];

    [[self.cancelButton titleLabel] setFont:[UIFont fontWithName:@"Ubuntu-Bold" size:self.cancelButton.titleLabel.font.pointSize]];
    [[self.cancelButton titleLabel] setTextColor:kShelbyColorWhite];

}

- (void)processingForm
{
    [self setUserInteractionEnabled:NO];
    [self.indicator startAnimating];
}

- (void)resetForm
{
    [self setUserInteractionEnabled:YES];
    [self.indicator stopAnimating];
}

- (BOOL)selectNextField:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    [self resetTextField:textField];
    
    return NO;
}

- (BOOL)validateFields
{
    return NO;
}

- (void)markTextField:(UITextField *)textField
{
    textField.layer.cornerRadius = 8.0f;
    textField.layer.masksToBounds = YES;
    textField.layer.borderColor = [[UIColor redColor] CGColor];
    textField.layer.borderWidth = 2.0f;
}

- (void)resetTextField:(UITextField *)textField
{
    textField.layer.borderColor = [[UIColor clearColor ]CGColor];
}

- (void)showErrors:(NSDictionary *)errors
{
    // Do nothing
}
@end
