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
- (void)followUser:(NSString *)publicRollID;
@end

@interface ShelbyUserProfileViewController : ShelbyHomeViewController

@end
