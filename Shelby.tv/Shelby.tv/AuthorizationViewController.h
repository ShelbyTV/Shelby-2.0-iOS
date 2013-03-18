//
//  AuthorizationViewController.h
//  Shelby.tv
//
//  Created by Keren on 3/13/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AuthorizationDelegate <NSObject>

- (void)authorizationDidComplete;

@end


@interface AuthorizationViewController : GAITrackedViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) id<AuthorizationDelegate> delegate;

@end