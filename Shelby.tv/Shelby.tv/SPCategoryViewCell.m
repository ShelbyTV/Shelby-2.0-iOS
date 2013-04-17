//
//  SPCategoryViewCell.m
//  Shelby.tv
//
//  Created by Keren on 4/15/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPCategoryViewCell.h"
#import "UIColor+ColorWithHexAndAlpha.h"

@interface SPCategoryViewCell()
@property (weak, nonatomic) IBOutlet UILabel *categoryTitle;
@property (weak, nonatomic) IBOutlet UIView *categoryColorView;
@end

@implementation SPCategoryViewCell


- (void)awakeFromNib
{
    [[self selectedBackgroundView] setBackgroundColor:[UIColor clearColor]];
    [self.contentView setBackgroundColor:[UIColor colorWithPatternImage:[UIImage imageNamed:@"channelbg.png"]]];

}

- (void)setcategoryColor:(NSString *)hex andTitle:(NSString *)title
{
    [self.categoryTitle setText:title];
    [self.categoryColorView setBackgroundColor:[UIColor colorWithHex:hex andAlpha:1]];    
}

@end
