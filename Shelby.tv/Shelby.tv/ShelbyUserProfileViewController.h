//
//  ShelbyUserProfileViewController.h
//  Shelby.tv
//
//  Created by Keren on 11/26/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ShelbyHomeViewController.h"

@protocol ShelbyUserProfileDelegate <NSObject>
- (void)followRoll:(NSString *)rollID;
- (void)unfollowRoll:(NSString *)rollID;
@end

@interface ShelbyUserProfileViewController : ShelbyHomeViewController

@property (nonatomic, weak) User *profileUser;

- (void)setIsLoading:(BOOL)isLoading;

@end
