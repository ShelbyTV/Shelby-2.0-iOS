//
//  CategoryRoll.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/5/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Category;

@interface CategoryRoll : NSManagedObject

@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) Category *category;

@end
