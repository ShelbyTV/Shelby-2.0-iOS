//
//  GroupViewCell.h
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GroupViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *groupDescription;
@property (weak, nonatomic) IBOutlet UILabel *groupTitle;
@property (weak, nonatomic) IBOutlet UIImageView *groupThumbnailImage;
@property (weak, nonatomic) IBOutlet UIView *selectionView;

- (void)enableCard:(BOOL)enabled;

@end
