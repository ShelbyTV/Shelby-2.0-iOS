//
//  ShelbyStreamEntryCell.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame.h"

#define kShelbyStreamEntryCaptionHeight 55

@protocol ShelbyStreamEntryProtocol <NSObject>
- (void)shareVideoWasTappedForFrame:(Frame *)videoFrame;
- (void)likeFrame:(Frame *)videoFrame;
- (void)unLikeFrame:(Frame *)videoFrame;
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
@end

@interface ShelbyStreamEntryCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic, weak) id<ShelbyStreamEntryProtocol> delegate;
@property (nonatomic, strong) User* currentUser;

- (void)setDashboardEntry:(DashboardEntry *)dashboardEntry andFrame:(Frame *)videoFrame;

- (void)selectStreamEntry;
- (void)deselectStreamEntry;
- (void)resizeCellAccordingToCaption;
+ (CGSize)sizeForCaptionWithText:(NSString *)text;
@end
