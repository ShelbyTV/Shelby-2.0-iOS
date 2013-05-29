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

@end

@interface SPShareController : NSObject <UITextViewDelegate, UIPopoverControllerDelegate>

@property (nonatomic, weak) id<SPShareControllerDelegate> delegate;

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer;
- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer fromRect:(CGRect)frame;

/// UI Methods
- (void)share;
- (void)showRollView;
- (void)hideRollView;

/// Action Methods
- (IBAction)cancelButtonAction:(id)sender;
- (IBAction)rollButtonAction:(id)sender;
- (IBAction)toggleSocialButtonStates:(id)sender;

@end
