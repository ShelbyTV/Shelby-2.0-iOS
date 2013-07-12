//
//  SignupConfirmationView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 7/12/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupConfirmationView : UIView

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *videoTypes;
@property (nonatomic, strong) NSString *socialNetworksConnected;

- (void)textFieldWillBeginEditing:(UITextField *)textField;
- (void)textFieldWillReturn:(UITextField *)textField;

@end
