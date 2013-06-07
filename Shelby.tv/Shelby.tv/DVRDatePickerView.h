//
//  DVRDatePickerView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DVRDatePickerView;

@protocol DVRDatePickerDelegate <NSObject>
- (void)cancelForDVRDatePickerView:(DVRDatePickerView *)view;
- (void)setDVRForDVRDatePickerView:(DVRDatePickerView *)view
                    withDatePicker:(UIDatePicker *)datePicker;
@end

@interface DVRDatePickerView : UIView

@property (nonatomic, weak) id<DVRDatePickerDelegate> delegate;

@property (nonatomic, strong) id entityForDVR;

@end
