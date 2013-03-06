//
//  CategoryViewCell.h
//  Shelby.tv
//
//  Created by Keren on 2/14/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryViewCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UILabel *categoryDescription;
@property (weak, nonatomic) IBOutlet UILabel *categoryTitle;
@property (weak, nonatomic) IBOutlet UIImageView *categoryThumbnailImage;
@property (weak, nonatomic) IBOutlet UIView *selectionView;

- (void)enableCard:(BOOL)enabled;

@end
