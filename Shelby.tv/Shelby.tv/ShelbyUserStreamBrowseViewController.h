//
//  ShelbyUserStreamBrowseViewController.h
//  Shelby.tv
//
//  Created by Keren on 11/29/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyStreamBrowseViewController.h"
#import "User.h"

@interface ShelbyUserStreamBrowseViewController : ShelbyStreamBrowseViewController
@property (nonatomic, strong) User *user;
@end
