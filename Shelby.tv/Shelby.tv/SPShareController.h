//
//  SPShareController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPVideoPlayer.h"

@interface SPShareController : NSObject <UITextViewDelegate>

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer;

/// UI Methods
- (void)share;
- (void)showRollView;
- (void)hideRollView;

/// Action Methods
- (IBAction)toggleSocialButtonStates:(id)sender;


@end
