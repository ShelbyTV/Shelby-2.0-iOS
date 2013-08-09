//
//  SPShareController.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import "Frame+Helper.h"

extern NSString * const kShelbyFacebookShareEnable;
extern NSString * const kShelbyTwitterShareEnable;
extern NSString * const kShelbyiOSNativeShareCancelled;
extern NSString * const kShelbyiOSNativeShareDone;

typedef void(^SPShareCompletionHandler)(BOOL completed);

@class SPShareController;

@protocol SPShareControllerDelegate <NSObject>
- (void)shareControllerRequestsFacebookPublishPermissions:(SPShareController *)shareController;
- (void)shareControllerRequestsTwitterPublishPermissions:(SPShareController *)shareController;
@end

@interface SPShareController : NSObject

@property (nonatomic, weak) id<SPShareControllerDelegate> delegate;

- (id)initWithVideoFrame:(Frame *)videoFrame fromViewController:(UIViewController *)viewController atRect:(CGRect)rect;

/// UI Methods
- (void)shareWithCompletionHandler:(SPShareCompletionHandler)completionHandler;
//DJS not sure when/why the following two are used, didn't touch them...

- (void)toggleSocialFacebookButton:(BOOL)facebook selected:(BOOL)selected;

- (void)shelbyShareWithMessage:(NSString *)message withFacebook:(BOOL)shareOnFacebook andWithTwitter:(BOOL)shareOnTwitter;
- (void)nativeShareWithFrame:(Frame *)frame message:(NSString *)message andLink:(NSString *)link fromViewController:(UIViewController *)viewController;

// Executes the completions handler.  Call when all is said and done.
- (void)shareComplete:(BOOL)didComplete;

@end
