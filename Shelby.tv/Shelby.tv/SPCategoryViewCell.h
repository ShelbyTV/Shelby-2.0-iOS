//
//  SPCategoryViewCell.h
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPCategoryViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UICollectionView *categoryFrames;

- (UIColor *)categoryDisplayColor;
- (NSString *)categoryDisplayTitle;
- (void)setcategoryColor:(NSString *)hex andTitle:(NSString *)title;
@end
