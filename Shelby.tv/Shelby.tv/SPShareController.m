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
#import "ShelbyAlert.h"
#import "ShelbyAPIClient.h"
#import "ShelbyDataMediator.h"
#import "ShelbyShareViewController.h"
#import "ShelbyViewController.h"
#import "SPVideoReel.h"
#import "TwitterHandler.h"
#import "User+Helper.h"

NSString * const kShelbyFacebookShareEnable = @"kShelbyFacebookShareEnable";
NSString * const kShelbyTwitterShareEnable  = @"kShelbyTwitterShareEnable";

NSString * const kShelbyiOSNativeShareDone = @"kShelbyiOSNativeShareDone";
NSString * const kShelbyiOSNativeShareCancelled  = @"kShelbyiOSNativeShareCancelled";

NSString * const kShelbyShareDestinationTwitter = @"twitter";
NSString * const kShelbyShareDestinationFacebook = @"facebook";

@interface SPShareController ()

@property (nonatomic, assign) CGRect rect;
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, strong) UIViewController *viewController;
@property (strong, nonatomic) UIPopoverController *sharePopOverController;
@property (strong, nonatomic) UIView *mask;

@property (nonatomic, strong) SPShareCompletionHandler completionHandler;

@property (nonatomic, strong) ShelbyAlert *currentAlertView;
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

#pragma mark - Action Methods (Public)
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
        [self shareOnSocialNetworks:frame message:message andLink:link fromViewController:self.viewController];
    }
}

- (UIActivityViewController *)activityViewControllerForFrame:(Frame *)frame withMessage:(NSString *)message withLink:(NSString *)link excludeFacebookAndTwitter:(BOOL)exclude
{
    
//    [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare
//                                     withAction:kAnalyticsShareActionShareButton
//                                      withLabel:[frame creatorsInitialCommentWithFallback:YES]];

    ShelbyActivityItemProvider *activity = [[ShelbyActivityItemProvider alloc] initWithShareText:message andShareLink:link];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[activity] applicationActivities:nil];
    
    if (exclude) {
        activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter];
    } else {
        activityController.excludedActivityTypes = @[UIActivityTypeCopyToPasteboard];
    }
    
    return activityController;
}


- (void)nativeShareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link fromViewController:(UIViewController *)viewController 
{
    UIActivityViewController *activityController = [self activityViewControllerForFrame:frame withMessage:message withLink:link excludeFacebookAndTwitter:YES];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
         if (completed) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyiOSNativeShareDone object:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyiOSNativeShareCancelled object:nil];
        }
    }];
    
    [viewController presentViewController:activityController animated:YES completion:nil];
}


- (void)shareOnSocialNetworks:(Frame *)frame message:(NSString *)message andLink:(NSString *)link fromViewController:(UIViewController *)viewController
{
    UIActivityViewController *activityController = [self activityViewControllerForFrame:frame withMessage:message withLink:link excludeFacebookAndTwitter:NO];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (self.completionHandler) {
            self.completionHandler(completed);
        }
        
//        if (completed) {
//            [ShelbyViewController sendEventWithCategory:kAnalyticsCategoryShare withAction:kAnalyticsShareActionShareSuccess withLabel:activityType];
//        }
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
    [viewController presentViewController:activityController animated:YES completion:nil];
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
                                  [self shareComplete:YES];
                              } else {
                                  [self shareComplete:NO];
                              }
                             
                          } else {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  self.currentAlertView = [[ShelbyAlert alloc] initWithTitle:NSLocalizedString(@"ROLLING_FAIL_TITLE", @"--Rolling Failed--")
                                                                                  message:NSLocalizedString(@"ROLLING_FAIL_MESSAGE", nil)
                                                                       dismissButtonTitle:NSLocalizedString(@"ROLLING_FAIL_BUTTON", nil)
                                                                           autodimissTime:0
                                                                                onDismiss:^(BOOL didAutoDimiss) {
                                                                                    [self shareComplete:NO];
                                                                                }];
                                  [self.currentAlertView show];
                              });
                          }
                      }];
}

- (void)shareComplete:(BOOL)didComplete
{
    if (self.completionHandler) {
        self.completionHandler(didComplete);
    }
}
@end
