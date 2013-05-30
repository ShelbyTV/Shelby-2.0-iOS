//
//  ShelbyAlertView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 5/15/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyAlertView.h"

#import <QuartzCore/QuartzCore.h>

@interface ShelbyAlertView ()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;

@property (assign, nonatomic) NSTimeInterval autodimissTime;
@property (strong, nonatomic) NSTimer *autodimissTimer;
@property (strong, nonatomic) alert_dismiss_block_t dismissBlock;

@end

@implementation ShelbyAlertView

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
 dismissButtonTitle:(NSString *)cancelButtonTitle
     autodimissTime:(NSTimeInterval)seconds
          onDismiss:(alert_dismiss_block_t)dismissBlock
{
    self = [[NSBundle mainBundle] loadNibNamed:@"ShelbyAlertView" owner:self options:nil][0];
    if (self) {
        _titleLabel.text = title;
        _messageLabel.text = message;
        [_cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
        _autodimissTime = seconds;
        _dismissBlock = dismissBlock;
    }
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.layer.borderColor = kShelbyColorOrange.CGColor;
    self.layer.borderWidth = 5;
}

- (void) show
{
    [self showAnimatedFromView:nil];
}

- (void) showAnimatedFromView:(UIView *)view
{
    //get topmost visible view
    UIViewController *topViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while ([topViewController presentedViewController]) {
        topViewController = [topViewController presentedViewController];
    }
    
    UIView *containerView = topViewController.view;
    
    //determine middle based on status bar orientation
    CGFloat hCenter, vCenter;
    switch ([[UIApplication sharedApplication] statusBarOrientation]) {
        case UIInterfaceOrientationLandscapeLeft:
        case UIInterfaceOrientationLandscapeRight:
            hCenter = containerView.frame.size.height/2;
            vCenter = containerView.frame.size.width/2;
            break;
        case UIInterfaceOrientationPortrait:
        case UIInterfaceOrientationPortraitUpsideDown:
            hCenter = containerView.frame.size.width/2;
            vCenter = containerView.frame.size.height/2;
            break;
    }
    
    //TODO: show it w/ animation baed on view
    self.frame = CGRectMake(hCenter - self.frame.size.width/2, vCenter - self.frame.size.height/2, self.frame.size.width, self.frame.size.height);
    self.alpha = 0.0f;
    [containerView addSubview:self];
    [UIView animateWithDuration:0.25f animations:^{
        [self setAlpha:1.0f];
    }];
    
    if(self.autodimissTime > 0){
        self.autodimissTimer = [NSTimer scheduledTimerWithTimeInterval:self.autodimissTime
                                                                target:self
                                                              selector:@selector(autodismiss:)
                                                              userInfo:nil
                                                               repeats:NO];
    }
}

- (IBAction)cancelPressed:(UIButton *)sender {
    [self.autodimissTimer invalidate];
    self.autodimissTimer = nil;
    
    [UIView animateWithDuration:0.25f animations:^{
        self.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        if (self.dismissBlock) {
            self.dismissBlock(sender == nil);
        }
    }];
}

- (void)autodismiss:(NSTimer*)theTimer
{
    [self cancelPressed:nil];
}

- (void)dismiss
{
    [self cancelPressed:nil];
}

@end
