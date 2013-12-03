//
//  StreamBrowseCellForegroundView.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 6/24/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame+Helper.h"


@protocol StreamBrowseCellForegroundViewDelegate <NSObject>
- (void)streamBrowseCellForegroundViewTitleWasTapped;
- (void)shareVideoWasTapped;
- (void)inviteFacebookFriendsWasTapped;
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersView;
@end


@interface StreamBrowseCellForegroundView : UIView
@property (nonatomic, assign) id<StreamBrowseCellForegroundViewDelegate>delegate;

// Summary play button is visible depending on what mode it's in.
@property (weak, nonatomic) IBOutlet UIImageView *summaryPlayImageView;

- (void)setInfoForDashboardEntry:(DashboardEntry *)dashboardEntry frame:(Frame *)videoFrame;

@end
