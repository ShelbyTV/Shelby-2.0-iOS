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
#import "ShelbyAPIClient.h"
#import "ShelbyDataMediator.h"
#import "ShelbyShareViewController.h"
#import "ShelbyViewController.h"
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
@property (nonatomic, strong) ShelbyShareViewController *shelbyShare;

@property (nonatomic, strong) SPShareCompletionHandler completionHandler;
@property (nonatomic, strong) UIPopoverController *popoverVC;

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
    if (!DEVICE_IPAD) {
        [self setupMaskView];
    }
    
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
// Return YES whether toggle was successfull. And NO if more permissions needs to be granted.
- (BOOL)toggleSocialFacebookButton:(BOOL)facebook selected:(BOOL)selected
{
    NSString *defaultsKey = facebook ? kShelbyFacebookShareEnable : kShelbyTwitterShareEnable;
    [[NSUserDefaults standardUserDefaults] setBool:selected forKey:defaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    User *currentUser = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
    
    if (selected) {
        if (facebook) {
            if (![[FacebookHandler sharedInstance] allowPublishActions]) {
                [ShelbyAnalyticsClient sendLocalyticsEventForStartConnectingAccountType:kLocalyticsAttributeValueAccountTypeFacebook
                                                                             fromOrigin:kLocalyticsAttributeValueFromOriginSharePane];
                if (DEVICE_IPAD) {
                    [[ShelbyDataMediator sharedInstance] userAskForFacebookPublishPermissions];
                } else {
                    [self.delegate shareControllerRequestsFacebookPublishPermissions:self];
                }
                return NO;
            }
        } else if (!currentUser.twitterNickname) {
            [ShelbyAnalyticsClient sendLocalyticsEventForStartConnectingAccountType:kLocalyticsAttributeValueAccountTypeTwitter
                                                                         fromOrigin:kLocalyticsAttributeValueFromOriginSharePane];
            if (DEVICE_IPAD) {
                User *user = [User currentAuthenticatedUserInContext:[[ShelbyDataMediator sharedInstance] mainThreadContext]];
                NSString *token = nil;
                if (user) {
                    token = user.token;
                }
                [[TwitterHandler sharedInstance] authenticateWithViewController:self.shelbyShare withDelegate:self.delegate andAuthToken:token];
            } else {
                [self.delegate shareControllerRequestsTwitterPublishPermissions:self];
            }
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Action Methods (Private)
- (void)shareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link
{
    User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
   
    if (user && ![user isAnonymousUser] && ![user.userID isEqualToString:frame.creator.userID]) {
        NSString *shareNibName = DEVICE_IPAD ? @"ShelbyShareView-iPad" : @"ShelbyShareView";
        self.shelbyShare = [[ShelbyShareViewController alloc] initWithNibName:shareNibName bundle:nil];
        [self.shelbyShare setupShareWith:frame link:link andShareController:self];
        if (DEVICE_IPAD) {
            self.shelbyShare.modalPresentationStyle = UIModalPresentationFormSheet;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyWillPresentModalViewNotification object:self];
        [self.viewController presentViewController:self.shelbyShare animated:YES completion:nil];
        if (DEVICE_IPAD) {
            self.shelbyShare.view.superview.bounds = CGRectMake(0, 0, 600, 355);
        }
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


- (void)nativeShareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link fromViewController:(UIViewController *)viewController inRect:(CGRect)positionFrame
{
    UIActivityViewController *activityController = [self activityViewControllerForFrame:frame withMessage:message withLink:link excludeFacebookAndTwitter:YES];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
         if (completed) {
             [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyiOSNativeShareDone object:nil];

             User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
             [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoShareComplete
                                         withAttributes:@{
                                                          @"user type" : [user userTypeStringForAnalytics],
                                                          @"title" : frame.video.title,
                                                          @"destinations" : [ShelbyAnalyticsClient destinationStringForUIActivityType:activityType]
                                                          }];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyiOSNativeShareCancelled object:nil];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyDidDismissModalViewNotification object:self];
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyWillPresentModalViewNotification object:self];
    
    if (DEVICE_IPAD) {
        self.popoverVC = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.popoverVC presentPopoverFromRect:positionFrame inView:viewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
     } else {
        [viewController presentViewController:activityController animated:YES completion:nil];
    }
}


- (void)shareOnSocialNetworks:(Frame *)frame message:(NSString *)message andLink:(NSString *)link fromViewController:(UIViewController *)viewController
{
    UIActivityViewController *activityController = [self activityViewControllerForFrame:frame withMessage:message withLink:link excludeFacebookAndTwitter:NO];
    
    [activityController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        if (self.completionHandler) {
            self.completionHandler(completed);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyDidDismissModalViewNotification object:self];
        
        if (completed) {
            User *user = [[ShelbyDataMediator sharedInstance] fetchAuthenticatedUserOnMainThreadContext];
            [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoShareComplete
                                        withAttributes:@{
                                                         @"user type" : [user userTypeStringForAnalytics],
                                                         @"title" : frame.video.title,
                                                         @"destinations" : [ShelbyAnalyticsClient destinationStringForUIActivityType:activityType]
                                                         }];
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kShelbyWillPresentModalViewNotification object:self];
    
    if (DEVICE_IPAD) {
        self.popoverVC = [[UIPopoverController alloc] initWithContentViewController:activityController];
        [self.popoverVC presentPopoverFromRect:_rect inView:viewController.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [viewController presentViewController:activityController animated:YES completion:nil];
    }
}


- (void)shelbyShareWithMessage:(NSString *)message withFacebook:(BOOL)shareOnFacebook andWithTwitter:(BOOL)shareOnTwitter
{
    NSString *frameID = self.videoFrame.frameID;
    User *user = [User currentAuthenticatedUserInContext:self.videoFrame.managedObjectContext];
    //TODO: this should go through the ShelbyDataMediator
    [ShelbyAPIClient rollFrame:frameID
                      onToRoll:user.publicRollID
                   withMessage:message
                     authToken:user.token
                      andBlock:^(id JSON, NSError *error) {
                          if (!error) {
                              // 1. Update My Shares (locally)
                              [[ShelbyDataMediator sharedInstance] fetchEntriesInChannel:[user displayChannelForSharesRoll] sinceEntry:nil];

                              // 2. share that freshly rolled frame!
                              NSDictionary *newFrameDict = JSON[@"result"];
                              if (newFrameDict && newFrameDict[@"id"]) {
                                  NSString *newFrameID = newFrameDict[@"id"];
                                  NSMutableArray *destinations = [@[] mutableCopy];
                                  NSString *shareDestinationsForLocalytics = @"shelby";
                                  if (shareOnTwitter) {
                                      [destinations addObject:kShelbyShareDestinationTwitter];
                                      shareDestinationsForLocalytics = [shareDestinationsForLocalytics stringByAppendingString:@", twitter"];
                                  }
                                  if (shareOnFacebook) {
                                      [destinations addObject:kShelbyShareDestinationFacebook];
                                      shareDestinationsForLocalytics = [shareDestinationsForLocalytics stringByAppendingString:@", facebook"];
                                  }
                                  if ([destinations count]){
                                      [ShelbyAPIClient shareFrame:newFrameID
                                           toExternalDestinations:destinations
                                                      withMessage:message
                                                     andAuthToken:user.token];
                                  }
                                  [self shareComplete:YES];
                                  [ShelbyAnalyticsClient sendLocalyticsEvent:kLocalyticsEventNameVideoShareComplete
                                                              withAttributes:@{
                                                                               @"user type" : [user userTypeStringForAnalytics],
                                                                               @"title" : newFrameDict[@"video"][@"title"],
                                                                               @"destinations" : shareDestinationsForLocalytics
                                                                               }];
                              } else {
                                  [self shareComplete:NO];
                              }
                             
                          } else {
                              dispatch_async(dispatch_get_main_queue(), ^{
                                  UIAlertView *currentAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"ROLLING_FAIL_TITLE", @"--Rolling Failed--") message:NSLocalizedString(@"ROLLING_FAIL_MESSAGE", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"ROLLING_FAIL_BUTTON", nil) otherButtonTitles:nil];
                                  [currentAlertView show];
                                  [self shareComplete:NO];
                              });
                          }
                      }];
}

- (void)shareComplete:(BOOL)didComplete
{
    if (self.completionHandler) {
        // TODO: KP KP: can refactor this into a method in an animation class. So we don't do the same thing in here and in liking.
        if (didComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"share-large"]];
                NSInteger imageHeight = imageView.frame.size.height;
                NSInteger imageWidth = imageView.frame.size.width;
                NSInteger viewHeight = self.viewController.view.frame.size.height;
                NSInteger viewWidth = self.viewController.view.frame.size.width;
                imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
                [self.viewController.view addSubview:imageView];
                [UIView animateWithDuration:0.1 animations:^{
                    imageView.frame = CGRectMake(viewWidth/2 - imageWidth/2, viewHeight/2 - imageHeight/2, imageWidth, imageHeight);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.3 animations:^{
                        imageView.alpha = 0.99;
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationCurveEaseIn animations:^{
                            imageView.frame = CGRectMake(viewWidth/2 - imageWidth/4, viewHeight/2 - imageHeight/4, imageWidth/2, imageHeight/2);
                            imageView.alpha = 0;
                        } completion:^(BOOL finished) {
                            [imageView removeFromSuperview];
                        }];
                    }];
                }];
            });
        }

        self.completionHandler(didComplete);
    }
}
@end
