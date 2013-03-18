//
//  FormView.m
//  Shelby.tv
//
//  Created by Keren on 3/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "FormView.h"

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

- (void)selectNextField:(UITextField *)textField
{
    [textField resignFirstResponder];
}

- (BOOL)validateFields
{
    return NO;
}

@end
