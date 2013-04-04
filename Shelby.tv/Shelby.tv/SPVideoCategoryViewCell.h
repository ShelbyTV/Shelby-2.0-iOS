//
//  SPVideoCategoryViewCell.h
//  Shelby.tv
//
//  Created by Keren on 4/4/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPVideoCategoryViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (assign, nonatomic) BOOL currentCategory;

@end
