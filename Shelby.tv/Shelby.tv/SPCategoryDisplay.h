//
//  SPCategoryDisplay.h
//  Shelby.tv
//
//  Created by Keren on 4/17/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SPCategoryDisplay : NSObject
@property (readonly) UIColor *categoryDisplayColor;
@property (readonly) NSString *categoryDisplayTitle;

-(id)initWithCategoryColor:(UIColor *)categoryDisplayColor andCategoryDisplayTitle:(NSString *)categoryDisplayTitle;
@end
