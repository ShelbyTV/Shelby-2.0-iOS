//
//  SPCategoryDisplay.m
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import "SPCategoryDisplay.h"
@interface SPCategoryDisplay()
@property (nonatomic, strong) UIColor *categoryDisplayColor;
@property (nonatomic, strong) NSString *categoryDisplayTitle;
@end

@implementation SPCategoryDisplay

-(id)initWithCategoryColor:(UIColor *)categoryDisplayColor andCategoryDisplayTitle:(NSString *)categoryDisplayTitle
{
    self = [super init];
    if (self) {
        _categoryDisplayColor = categoryDisplayColor;
        _categoryDisplayTitle = categoryDisplayTitle;
    }
    
    return self;
}
@end
