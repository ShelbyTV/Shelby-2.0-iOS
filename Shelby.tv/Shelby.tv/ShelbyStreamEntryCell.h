//
//  ShelbyStreamEntryCell.h
//  Shelby.tv
//
//  Created by Keren on 1/9/14.
//  Copyright (c) 2014 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame.h"

@protocol ShelbyStreamEntryProtocol <NSObject>
- (void)shareVideoWasTappedForFrame:(Frame *)videoFrame;
- (void)likeFrame:(Frame *)videoFrame;
- (void)unLikeFrame:(Frame *)videoFrame;
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersViewForVideo:(Video *)video withLikers:(NSMutableOrderedSet *)likers;
@end

@interface ShelbyStreamEntryCell : UITableViewCell
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, weak) IBOutlet UILabel *description;
@property (nonatomic, weak) id<ShelbyStreamEntryProtocol> delegate;

- (void)selectStreamEntry;
- (void)deselectStreamEntry;
@end
