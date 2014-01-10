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
- (void)toggleLikeForFrame:(Frame *)videoFrame;
- (void)userProfileWasTapped:(NSString *)userID;
- (void)openLikersView:(NSMutableOrderedSet *)likers;
@end

@interface ShelbyStreamEntryCell : UITableViewCell
@property (nonatomic, strong) Frame *videoFrame;
@property (nonatomic, weak) id<ShelbyStreamEntryProtocol> delegate;

@end
