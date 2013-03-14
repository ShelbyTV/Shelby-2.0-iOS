//
//  FormView.h
//  Shelby.tv
//
//  Created by Keren on 3/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FormView : UIView

- (void)processingForm;
- (void)resetForm;
- (void)selectNextField:(UITextField *)textField;
- (BOOL)validateFields;

@end
