//
//  ShelbyAlertView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAlert.h"

@interface ShelbyAlert ()
@property (assign, nonatomic) NSTimeInterval autodimissTime;
@property (strong, nonatomic) NSTimer *autodimissTimer;
@property (strong, nonatomic) UIAlertView *alertView;
@property (strong, nonatomic) alert_dismiss_block_t dismissBlock;

@end

@implementation ShelbyAlert

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
 dismissButtonTitle:(NSString *)cancelButtonTitle
     autodimissTime:(NSTimeInterval)seconds
          onDismiss:(alert_dismiss_block_t)dismissBlock
{
    self = [super init];
    if (self) {
        _alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
        _autodimissTime = seconds;
        _dismissBlock = dismissBlock;
    }
    return self;
}

- (void) show
{
    [self.alertView show];
    
    if(self.autodimissTime > 0){
        self.autodimissTimer = [NSTimer scheduledTimerWithTimeInterval:self.autodimissTime
                                                                target:self
                                                              selector:@selector(autodismiss:)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

- (void)cancelPressed:(BOOL)autoDismiss {
    
    [self.autodimissTimer invalidate];
    self.autodimissTimer = nil;
    
    if (self.dismissBlock) {
        self.dismissBlock(autoDismiss);
    }
}

- (void)autodismiss:(NSTimer*)theTimer
{
    [self dismiss];
}

// Dismiss initiated by us (somewhere else in the code) or by the autodismiss timer.
- (void)dismiss
{
    [self.alertView dismissWithClickedButtonIndex:0 animated:YES];

    [self cancelPressed:YES];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Dismiss initiated by user.
    [self cancelPressed:NO];
}

@end
