//
//  TriageViewController.h
//  Shelby.tv
//
//  Created by Keren on 6/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayChannel.h"
#import "MCSwipeTableViewCell.h"

@protocol ShelbyTriageProtocol <NSObject>
- (void)userPressedTriageChannel:(DisplayChannel *)channel atItem:(id)item;
@end

@interface TriageViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, MCSwipeTableViewCellDelegate>

@property (nonatomic, strong) NSArray *itemsToTriage;
@property (nonatomic, strong) DisplayChannel *triageChannel;
@property (weak, nonatomic) id<ShelbyTriageProtocol> triageDelegate;

@end

