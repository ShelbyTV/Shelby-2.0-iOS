//
//  FormView.h
//  Shelby.tv
//
//  Created by Keren on 3/14/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FormView : UIView

/** Should be called when processing is done - disable all form fiels and show a spinner
 */
- (void)processingForm;

/** Resets the form and makes the first text field first responder
 */
- (void)resetForm;

/** Selects the next text field in the form
 *  Returns YES - if next text field selected
 *  Returns NO  - if there is no more text fields in the form
 */
- (BOOL)selectNextField:(UITextField *)textField;

/** Validates that form fields are not empty
 *  Returns YES all fields are not empty
*/
- (BOOL)validateFields;

/** Marks text field with red borders
 */
- (void)markTextField:(UITextField *)textField;

/** Resets text field - removes red border
 */
- (void)resetTextField:(UITextField *)textField;

/** Mark textfields with errors 
 */
- (void)showErrors:(NSDictionary *)errors;
@end
