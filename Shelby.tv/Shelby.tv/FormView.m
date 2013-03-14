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

@end

@implementation FormView
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
