//
//  ShelbyAlertView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^alert_dismiss_block_t)(BOOL didAutoDimiss);

@interface ShelbyAlertView : UIView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
 dismissButtonTitle:(NSString *)cancelButtonTitle
     autodimissTime:(NSTimeInterval)seconds
          onDismiss:(alert_dismiss_block_t)dismissBlock;

- (void) show;
- (void) showAnimatedFromView:(UIView *)view;
- (void) dismiss;

@end
