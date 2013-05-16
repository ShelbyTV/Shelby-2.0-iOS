//
//  SPVideoItemViewCell.h
//  Shelby.tv
//
//  Created by Keren on 4/12/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Frame.h"

@class SPVideoItemViewCellLabel;

@interface SPVideoItemViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet SPVideoItemViewCellLabel *caption;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

//the currently displayed frame
@property (strong, nonatomic) Frame *shelbyFrame;

- (void)highlightItemWithColor:(UIColor *)color;
- (void)unHighlightItem;
@end
