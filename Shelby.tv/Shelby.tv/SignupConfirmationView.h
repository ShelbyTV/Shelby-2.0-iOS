//
//  SignupConfirmationView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupConfirmationView : UIView

- (void)textFieldWillBeginEditing:(UITextField *)textField;
- (void)textFieldWillReturn:(UITextField *)textField;

@end
