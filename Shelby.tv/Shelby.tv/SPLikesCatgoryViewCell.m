//
//  SPLikesCatgoryViewCell.m
//  Shelby.tv
//
//  Created by Keren on 4/8/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPLikesCatgoryViewCell.h"

@interface SPLikesCatgoryViewCell()
@property (weak, nonatomic) IBOutlet UIImageView *heart;
@end

@implementation SPLikesCatgoryViewCell


- (void)setCurrentCategory:(BOOL)currentCategory
{
    [super setCurrentCategory:currentCategory];
    
    if (currentCategory) {
        [self.heart setImage:[UIImage imageNamed:@"heartwhite.png"]];
    } else {
        [self.heart setImage:[UIImage imageNamed:@"heart.png"]];
    }
}

@end
