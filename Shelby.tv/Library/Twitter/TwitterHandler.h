//
//  TwitterHandler.h
//  TwitterHandler
//
//  Created by Arthur Ariel Sabintsev on 4/18/12.
//  Copyright (c) 2012 ArtSabintsev. All rights reserved.
//

#import "User.h"

FOUNDATION_EXPORT NSString * const kShelbyNotificationTwitterAuthorizationCompleted;

@protocol TwitterHandlerDelegate <NSObject>

- (void)twitterConnectDidComplete;
- (void)twitterConnectDidCompleteWithError:(NSString *)errorMessage;

@end


@interface TwitterHandler : NSObject <UIActionSheetDelegate>

+ (TwitterHandler *)sharedInstance;
- (void)authenticateWithViewController:(UIViewController *)viewController andDelegate:(id)delegate;

/// Cleanup
- (void)twitterCleanup;
@end
