//
//  SignupHeaderView.h
//  Shelby.tv
//
//  Created by Keren on 1/24/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol SignupHeaderDelegate <NSObject>
- (void)signupUser;
@end

@interface SignupHeaderView : UIView
@property (nonatomic, weak) id<SignupHeaderDelegate> delegate;
@end
