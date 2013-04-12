//
//  TwitterHandler.h
//  TwitterHandler
//
//  Created by Arthur Ariel Sabintsev on 4/18/12.
//  Copyright (c) 2012 ArtSabintsev. All rights reserved.
//

FOUNDATION_EXPORT NSString * const kShelbyNotificationTwitterAuthorizationCompleted;

@interface TwitterHandler : NSObject <UIActionSheetDelegate>

+ (TwitterHandler *)sharedInstance;
- (void)authenticateWithViewController:(UIViewController *)viewController;;

@end
