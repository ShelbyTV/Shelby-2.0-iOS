//
//  TriageCell.h
//  Shelby.tv
//
//  Created by Keren on 6/3/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame.h"
#import "MCSwipeTableViewCell.h"
#import "SPVideoItemViewCellLabel.h"

@interface SPTriageCell : MCSwipeTableViewCell
@property (weak, nonatomic) IBOutlet SPVideoItemViewCellLabel *caption;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;
@property (weak, nonatomic) IBOutlet UIImageView *userImageView;
@property (weak, nonatomic) IBOutlet UILabel *nicknameLabel;
@property (strong, nonatomic) Frame *shelbyFrame;

- (void)highlightItemWithColor:(UIColor *)color;
- (void)unHighlightItem;
@end
