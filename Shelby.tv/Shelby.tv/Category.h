//
//  Category.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/29/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CategoryRoll;

@interface Category : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSSet *categoryRoll;
@end

@interface Category (CoreDataGeneratedAccessors)

- (void)addCategoryRollObject:(CategoryRoll *)value;
- (void)removeCategoryRollObject:(CategoryRoll *)value;
- (void)addCategoryRoll:(NSSet *)values;
- (void)removeCategoryRoll:(NSSet *)values;

@end
