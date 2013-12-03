//
//  ShelbyLikersViewController.h
//  Shelby.tv
//
//  Created by Keren on 12/2/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LikerCell.h"

@protocol ShelbyLikersViewDelegate <NSObject>
- (void)userProfileWasTapped:(NSString *)userID;
- (void)followUser:(NSString *)publicRollID;
@end


@interface ShelbyLikersViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, LikerCellDelegate>
@property (nonatomic, strong) NSMutableOrderedSet *localLikers;

@property (nonatomic, weak) id<ShelbyLikersViewDelegate> delegate;
@end
