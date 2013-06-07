//
//  DVRDatePickerView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/7/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "DVRDatePickerView.h"

@interface DVRDatePickerView()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end

@implementation DVRDatePickerView

- (id)init
{
    self = [[NSBundle mainBundle] loadNibNamed:@"DVRDatePicker" owner:self options:nil][0];
    if (self) {
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (IBAction)cancelTapped:(UIButton *)sender {
    [self.delegate cancelForDVRDatePickerView:self];
}

- (IBAction)setDVRTapped:(UIButton *)sender {
    [self.delegate setDVRForDVRDatePickerView:self withDatePicker:self.datePicker];
}

@end
