//
//  SPShareController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPShareController.h"

#import "AFNetworking.h"
#import "AsynchronousFreeloader.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "ShelbyActivityItemProvider.h"
#import "ShelbyAlertView.h"
#import "ShelbyAPIClient.h"
#import "ShelbyViewController.h"
#import "SPShareRollView.h"
#import "SPVideoReel.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

#define kShelbyFacebookShareEnable  @"kShelbyFacebookShareEnable"
#define kShelbyTwitterShareEnable   @"kShelbyTwitterShareEnable"

NSString * const kShelbyShareDestinationTwitter = @"twitter";
NSString * const kShelbyShareDestinationFacebook = @"facebook";

@interface SPShareController ()

@property (weak, nonatomic) SPVideoPlayer *videoPlayer;
@property (nonatomic, assign) CGRect fromFrame;
@property (nonatomic) SPShareRollView *rollView;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;
@property (assign, nonatomic) BOOL facebookConnected;
@property (assign, nonatomic) BOOL twitterConnected;
@property (strong, nonatomic) UIView *mask;

@end

@implementation SPShareController

#pragma mark - Initialization
- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer
{
    self = [super init];
    if (self) {
        _videoPlayer = videoPlayer;
    }
    
    return self;
}

- (id)initWithVideoPlayer:(SPVideoPlayer *)videoPlayer fromRect:(CGRect)frame
{
    self = [super init];
     if (self) {
         _videoPlayer = videoPlayer;
         _fromFrame = frame;
     }
     
     return self;
}

- (void)updateSocialButtons
{
    User *user = [User currentAuthenticatedUserInContext:self.videoPlayer.videoFrame.managedObjectContext];
    if (user) {
        self.facebookConnected = user.facebookNickname && [[FacebookHandler sharedInstance] allowPublishActions] && [[NSUserDefaults standardUserDefaults] boolForKey: kShelbyFacebookShareEnable] ? YES : NO;
        self.twitterConnected = user.twitterNickname && [[NSUserDefaults standardUserDefaults] objectForKey:kShelbyTwitterShareEnable] ? YES : NO;
    } else {
        self.facebookConnected = NO;
        self.twitterConnected = NO;
    }

    self.rollView.facebookButton.selected = self.facebookConnected;
    self.rollView.twitterButton.selected = self.twitterConnected;
}

#pragma mark - Setup Methods
- (void)updateFacebookToggle
{
    if (self.rollView && self.rollView.facebookButton && [self.rollView.facebookButton isKindOfClass:[UIButton class]]) {
        [self updateSocialButtons];
    }
}

- (void)updateTwitterToggle
{
    if (self.rollView && self.rollView.twitterButton && [self.rollView.twitterButton isKindOfClass:[UIButton class]]) {
        [self updateSocialButtons];
    }
}

- (void)setupMaskView
{
    CGRect videoPlayerFrame = self.videoPlayer.view.frame;
    _mask = [[UIView alloc] initWithFrame:CGRectMake(videoPlayerFrame.origin.x, videoPlayerFrame.origin.y, videoPlayerFrame.size.width, videoPlayerFrame.size.height)];
    [self.mask setBackgroundColor:[UIColor blackColor]];
    [self.mask setAlpha:0.0f];
    [self.mask setUserInteractionEnabled:YES];
}

#pragma mark - UI Methods (Public)
- (void)share
{
    [self setupMaskView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                     }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        Frame *videoFrame = self.videoPlayer.videoFrame;
        
        [ShelbyAPIClient getShortlinkForFrame:self.videoPlayer.videoFrame
                                allowFallback:YES
                                    withBlock:^(NSString *link, BOOL shortlinkDidFail) {
                                        NSString *shareMessage = [NSString stringWithFormat:@"%@", videoFrame.video.title];
                                        [self shareWithFrame:videoFrame
                                                     message:shareMessage
                                                     andLink:link];
                                    }];
    });
    
}

- (void)showRollView
{
    [self setupMaskView];
    
    // Instantiate rollView
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"SPShareRollView" owner:self options:nil];
    if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
        return;
    }

    self.rollView = nib[0];
    
    Frame *videoFrame = self.videoPlayer.videoFrame;
    [self.rollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"rollingContainer.png"]]];
    
    // Load Thumbnail
    //djs TODO: use AFNetworking
    [AsynchronousFreeloader loadImageFromLink:videoFrame.video.thumbnailURL
                                 forImageView:_rollView.videoThumbnailView
                              withPlaceholder:nil
                               andContentMode:UIViewContentModeScaleAspectFill];
    
    // Set proper states for buttons
    [self updateSocialButtons];
    
    CGFloat xOrigin = self.videoPlayer.view.frame.size.width/2.0f - _rollView.frame.size.width/2.0f;
    // This is the bottom of the video view in overlay view, so we don't go under it. TODO: when we redo all this, make the share view go ABOVE overlay view.
    CGFloat yOrigin = 160;
    
    [self.rollView setFrame:CGRectMake(xOrigin,
                                       _videoPlayer.view.frame.size.height,
                                       _rollView.frame.size.width,
                                       _rollView.frame.size.height)];
   
    [self.videoPlayer.view addSubview:self.rollView];
    [self.videoPlayer.view bringSubviewToFront:self.rollView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            yOrigin,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView becomeFirstResponder];
                         [self.videoPlayer pause];
                         
                     }];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(updateFacebookToggle)
                                                    name:kShelbyNotificationFacebookAuthorizationCompleted object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateTwitterToggle)
                                                 name:kShelbyNotificationTwitterAuthorizationCompleted object:nil];

}

- (void)hideRollView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.videoPlayer.view.frame.size.width/2.0f - _rollView.frame.size.width/2.0f;
                         [self.mask setAlpha:0];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            self.videoPlayer.view.frame.size.height,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                         [self.rollView.rollTextView resignFirstResponder];
                         [self.rollView removeFromSuperview];
                         [self.videoPlayer play];
                         
                     }];
}

#pragma mark - Action Methods (Public)
- (IBAction)cancelButtonAction:(id)sender
{
    [self hideRollView];
}

- (IBAction)rollButtonAction:(id)sender
{
    [self roll];
}

- (IBAction)toggleSocialButtonStates:(id)sender
{
    if (sender == self.rollView.facebookButton || sender == self.rollView.twitterButton) {
        BOOL facebookToggle = sender == self.rollView.facebookButton ? YES : NO;
        
        BOOL selectionToggle = ![sender isSelected];
        [sender setSelected:selectionToggle];
        
        NSString *defaultsKey = facebookToggle ? kShelbyFacebookShareEnable : kShelbyTwitterShareEnable;
        [[NSUserDefaults standardUserDefaults] setBool:selectionToggle forKey:defaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    
    
        if (selectionToggle) {
            if (facebookToggle) {
                if (![[FacebookHandler sharedInstance] allowPublishActions]) {
                    [self.delegate userAskForFacebookPublishPermissions];
                }
            } else if (!self.twitterConnected) {
                [self.delegate userAskForTwitterPublishPermissions];
            }
        }
    }
}

#pragma mark - Action Methods (Private)
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{
    ShelbyActivityItemProvider *activity = [[ShelbyActivityItemProvider alloc] initWithShareText:message andShareLink:link];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[activity] applicationActivities:nil];
    activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
    
    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare
                                     withAction:kAnalyticsShareActionShareButton
                                      withLabel:[frame creatorsInitialCommentWithFallback:YES]];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        [self.delegate shareDidFinish:completed];
        if (completed && ![activityType isEqualToString:kShelbySPActivityTypeRoll]) {
            [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare withAction:kAnalyticsShareActionShareSuccess withLabel:activityType];
        }
    }];

    if ( ![self sharePopOverController] ) {
        self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.sharePopOverController setDelegate:self];
        [self.sharePopOverController presentPopoverFromRect:self.fromFrame
                                                     inView:self.videoPlayer.view
                                   permittedArrowDirections:UIPopoverArrowDirectionDown
                                                   animated:YES];
    }
}

- (void)roll
{
    NSString *frameID = self.videoPlayer.videoFrame.frameID;
    User *user = [User currentAuthenticatedUserInContext:self.videoPlayer.videoFrame.managedObjectContext];
    NSString *message = self.rollView.rollTextView.text;

    [ShelbyAPIClient rollFrame:frameID
                      onToRoll:user.publicRollID
                   withMessage:message
                     authToken:user.token
                      andBlock:^(id JSON, NSError *error) {
                          if (!error) {
                              // share that freshly rolled frame!
                              NSDictionary *newFrameDict = JSON[@"result"];
                              if (newFrameDict && newFrameDict[@"id"]) {
                                  NSString *newFrameID = newFrameDict[@"id"];
                                  NSMutableArray *destinations = [@[] mutableCopy];
                                  if ([_rollView.twitterButton isSelected]) {
                                      [destinations addObject:kShelbyShareDestinationTwitter];
                                  }
                                  if ([_rollView.facebookButton isSelected]) {
                                      [destinations addObject:kShelbyShareDestinationFacebook];
                                  }
                                  if ([destinations count]){
                                      [ShelbyAPIClient shareFrame:newFrameID
                                           toExternalDestinations:destinations
                                                      withMessage:message
                                                     andAuthToken:user.token];
                                  }
                              }
                             
                          } else {
                              dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                  ShelbyAlertView *alert = [[ShelbyAlertView alloc] initWithTitle:NSLocalizedString(@"ROLLING_FAIL_TITLE", @"--Rolling Failed--")
                                                                                         message:NSLocalizedString(@"ROLLING_FAIL_MESSAGE", nil)
                                                                              dismissButtonTitle:NSLocalizedString(@"ROLLING_FAIL_BUTTON", nil)
                                                                                  autodimissTime:0
                                                                                       onDismiss:nil];
                                  [alert show];
                              });
                          }
                         
                          [self performSelectorOnMainThread:@selector(hideRollView) withObject:nil waitUntilDone:NO];
                      }];
}

#pragma mark - UITextViewDelegate Methods
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ( [text isEqualToString:@"\n"] && [textView.text length] > 0 ) {
        [self.rollView.rollTextView resignFirstResponder];
        return NO;
    }
    
    return YES;
}

#pragma mark - UIPopoverControllerDelegate Methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         [self.mask setAlpha:0.0f];
                     } completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                     }];
}

@end
