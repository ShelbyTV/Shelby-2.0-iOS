//
//  SPShareController.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "SPShareController.h"

#import "AFNetworking.h"
#import "FacebookHandler.h"
#import "Frame+Helper.h"
#import "ShelbyActivityItemProvider.h"
#import "ShelbyAlertView.h"
#import "ShelbyAPIClient.h"
#import "ShelbyDataMediator.h"
#import "ShelbyShareViewController.h"
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

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, strong) UIViewController *viewController;
@property (nonatomic) SPShareRollView *rollView;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;
@property (strong, nonatomic) UIView *mask;

@property (nonatomic, strong) SPShareCompletionHandler completionHandler;

@end

@implementation SPShareController

- (id)initWithVideoFrame:(Frame *)videoFrame fromViewController:(UIViewController *)viewController atRect:(CGRect)rect
{
    self = [super init];
    if (self) {
        _videoFrame = videoFrame;
        _viewController = viewController;
        _rect = rect;
    }

    return self;
}


#pragma mark - Setup Methods

- (void)setupMaskView
{
    CGRect videoPlayerFrame = self.viewController.view.frame;
    _mask = [[UIView alloc] initWithFrame:CGRectMake(videoPlayerFrame.origin.x, videoPlayerFrame.origin.y, videoPlayerFrame.size.width, videoPlayerFrame.size.height)];
    [self.mask setBackgroundColor:[UIColor blackColor]];
    [self.mask setAlpha:0.0f];
    [self.mask setUserInteractionEnabled:YES];
}

#pragma mark - UI Methods (Public)
- (void)shareWithCompletionHandler:(SPShareCompletionHandler)completionHandler
{
    self.completionHandler = completionHandler;
    [self setupMaskView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                     }];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        Frame *videoFrameToShare = self.videoFrame;
        
        [ShelbyAPIClient getShortlinkForFrame:videoFrameToShare
                                allowFallback:YES
                                    withBlock:^(NSString *link, BOOL shortlinkDidFail) {
                                        NSString *shareMessage = [NSString stringWithFormat:@"%@", videoFrameToShare.video.title];
                                        [self shareWithFrame:videoFrameToShare
                                                     message:shareMessage
                                                     andLink:link];
                                    }];
    });
    
}

- (void)showRollView
{
    [self setupMaskView];
    
    NSString *shareNibName = nil;
//    if (DEVICE_IPAD) {
//        shareNibName = @"SPShareRollView";
//    } else {
    shareNibName = @"SPShareRollView-iPhone";
//    }
    // Instantiate rollView
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:shareNibName owner:self options:nil];
    if (![nib isKindOfClass:[NSArray class]] || [nib count] == 0 || ![nib[0] isKindOfClass:[UIView class]]) {
        return;
    }

    self.rollView = nib[0];
    
    NSString *containerBackground = nil;
//    if (DEVICE_IPAD) {
//        containerBackground = @"rollingContainer.png";
//    } else {
    containerBackground = @"rollingContainer-iPhone.png";
//    }
    
    [self.rollView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:containerBackground]]];
    
    // Set Thumbnail
    NSURLRequest *imageRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:self.videoFrame.video.thumbnailURL]];
    [[AFImageRequestOperation imageRequestOperationWithRequest:imageRequest
                                          imageProcessingBlock:nil
                                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                           self.rollView.videoThumbnailView.image = image;
                                                       }
                                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                           //ignoring for now
                                                       }] start];

    // Set proper states for buttons
//    [self updateSocialButtons];
    
    CGFloat xOrigin = self.viewController.view.bounds.size.width/2.0f - _rollView.frame.size.width/2.0f;
    // This is the bottom of the video view in overlay view, so we don't go under it. TODO: when we redo all this, make the share view go ABOVE overlay view.
//    CGFloat yOrigin = 160;
//    if (!DEVICE_IPAD) {
    CGFloat yOrigin = yOrigin = 0;
//    }
    
    [self.rollView setFrame:CGRectMake(xOrigin,
                                       self.viewController.view.bounds.size.height,
                                       _rollView.frame.size.width,
                                       _rollView.frame.size.height)];
   
    [self.viewController.view addSubview:self.rollView];
    [self.viewController.view bringSubviewToFront:self.rollView];
    
    [UIView animateWithDuration:0.5f
                     animations:^{
                         [self.mask setAlpha:0.7];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            yOrigin,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         
                         [self.rollView.rollTextView becomeFirstResponder];
                     }];
    
}

- (void)hideRollView
{
    [UIView animateWithDuration:0.5
                     animations:^{
                         
                         CGFloat xOrigin = self.viewController.view.bounds.size.width/2.0f - _rollView.frame.size.width/2.0f;
                         [self.mask setAlpha:0];
                         [self.rollView setFrame:CGRectMake(xOrigin,
                                                            self.viewController.view.bounds.size.height,
                                                            _rollView.frame.size.width,
                                                            _rollView.frame.size.height)];
                         
                     } completion:^(BOOL finished) {
                         [self.mask removeFromSuperview];
                         [self.rollView.rollTextView resignFirstResponder];
                         [self.rollView removeFromSuperview]; 
                     }];
}

#pragma mark - Action Methods (Public)
- (IBAction)cancelButtonAction:(id)sender
{
    [self hideRollView];
}

//- (IBAction)rollButtonAction:(id)sender
//{
//    [self roll];
//}

- (void)toggleSocialFacebookButton:(BOOL)facebook selected:(BOOL)selected
{
    NSString *defaultsKey = facebook ? kShelbyFacebookShareEnable : kShelbyTwitterShareEnable;
    [[NSUserDefaults standardUserDefaults] setBool:selected forKey:defaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    if (selected) {
        if (facebook) {
            if (![[FacebookHandler sharedInstance] allowPublishActions]) {
                [self.delegate shareControllerRequestsFacebookPublishPermissions:self];
            }
        } else {
            [self.delegate shareControllerRequestsTwitterPublishPermissions:self];
        }
    }
}

#pragma mark - Action Methods (Private)
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
   
    if (user) {
        ShelbyShareViewController *shelbyShare = [[ShelbyShareViewController alloc] initWithNibName:@"ShelbyShareView" bundle:nil];
        [shelbyShare setupShareWith:frame link:link andShareController:self];
        [self.viewController presentViewController:shelbyShare animated:YES completion:nil];
    } else {
        [self shareOnSocialNetworks:frame message:message andLink:link];
    }
}

- (void)shareOnSocialNetworks:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{
    ShelbyActivityItemProvider *activity = [[ShelbyActivityItemProvider alloc] initWithShareText:message andShareLink:link];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[activity] applicationActivities:nil];
    activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
    
    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare
                                     withAction:kAnalyticsShareActionShareButton
                                      withLabel:[frame creatorsInitialCommentWithFallback:YES]];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (self.completionHandler) {
            self.completionHandler(completed);
        }
        
        if (completed && ![activityType isEqualToString:kShelbySPActivityTypeRoll]) {
            [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare withAction:kAnalyticsShareActionShareSuccess withLabel:activityType];
        }
    }];

//    if (DEVICE_IPAD) {
//        if ( ![self sharePopOverController] ) {
//            self.sharePopOverController = [[UIPopoverController alloc] initWithContentViewController:activityController];
//            [self.sharePopOverController setDelegate:self];
//            [self.sharePopOverController presentPopoverFromRect:self.rect
//                                                         inView:self.viewController.view
//                                       permittedArrowDirections:UIPopoverArrowDirectionDown
//                                                       animated:YES];
//        }
//    } else {
    [self.viewController presentViewController:activityController animated:YES completion:nil];
//    }
}


- (void)shelbyShareWithMessage:(NSString *)message withFacebook:(BOOL)shareOnFacebook andWithTwitter:(BOOL)shareOnTwitter
{
    NSString *frameID = self.videoFrame.frameID;
    User *user = [User currentAuthenticatedUserInContext:self.videoFrame.managedObjectContext];
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
                                  if (shareOnTwitter) {
                                      [destinations addObject:kShelbyShareDestinationTwitter];
                                  }
                                  if (shareOnFacebook) {
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
