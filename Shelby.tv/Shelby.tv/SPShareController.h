//
//  SPShareController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPVideoPlayer.h"

@protocol SPShareControllerDelegate <NSObject>

- (void)shareDidFinish:(BOOL)complete;
- (void)userAskForFacebookPublishPermissions;
- (void)userAskForTwitterPublishPermissions;
@end

@interface SPShareController : NSObject <UITextViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) id<SPShareControllerDelegate> delegate;

- (id)initWithVideoFrame:(Frame *)videoFrame fromViewController:(UIViewController *)viewController atRect:(CGRect)rect withVideoPlayer:(SPVideoPlayer *)videoPlayer;
- (id)initWithVideoFrame:(Frame *)videoFrame fromViewController:(UIViewController *)viewController atRect:(CGRect)rect;
/// UI Methods
- (void)share;
- (void)showRollView;
- (void)hideRollView;

/// Action Methods
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)rollButtonAction:(id)sender;
- (IBAction)toggleSocialButtonStates:(id)sender;

@end
