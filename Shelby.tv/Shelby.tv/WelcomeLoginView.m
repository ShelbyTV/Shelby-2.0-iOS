//
//  WelcomeLoginView.m
//  Shelby.tv
//
//  Created by Daniel Spinosa on 8/28/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "WelcomeLoginView.h"

@interface WelcomeLoginView()
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *signupWithFacebookButton;
@property (weak, nonatomic) IBOutlet UIButton *createAccountButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *previewButton;

//blurry background
@property (weak, nonatomic) IBOutlet UIView *blurryBackgroundHolder;
@property (weak, nonatomic) IBOutlet UIImageView *currentlyShowingBackground;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *allBackgrounds;
@end

@implementation WelcomeLoginView

- (void)awakeFromNib
{
    [self.loginButton setBackgroundImage:[[UIImage imageNamed:@"green-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
    [self.signupWithFacebookButton setBackgroundImage:[[UIImage imageNamed:@"facebook-button-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)] forState:UIControlStateNormal];
}

- (void)setRunBackgroundAnimation:(BOOL)runBackgroundAnimation
{
    if (_runBackgroundAnimation != runBackgroundAnimation) {
        _runBackgroundAnimation = runBackgroundAnimation;
        if (_runBackgroundAnimation) {
            [self stepBackgroundAnimation];
        }
    }
}

#pragma mark - Background Animation

- (void)stepBackgroundAnimation
{
    if (self.runBackgroundAnimation) {
        NSMutableArray *hiddenBackgrounds = [self.allBackgrounds mutableCopy];
        [hiddenBackgrounds removeObject:self.currentlyShowingBackground];
        UIImageView *nextBackground = hiddenBackgrounds[arc4random_uniform((u_int32_t) [hiddenBackgrounds count])];
        nextBackground.alpha = 1.f;
        [self.blurryBackgroundHolder insertSubview:nextBackground belowSubview:self.currentlyShowingBackground];
        
        [UIView animateWithDuration:5.0f animations:^{
            self.currentlyShowingBackground.alpha = 0.f;
            
        } completion:^(BOOL finished) {
            self.currentlyShowingBackground = nextBackground;
            if (finished) {
                [self stepBackgroundAnimation];
            }
        }];
        
    } else {
        //we've been asked to stop, do nothing
    }
}

@end
