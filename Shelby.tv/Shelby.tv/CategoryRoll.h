//
//  CategoryRoll.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 1/29/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CategoryRoll : NSManagedObject

@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSManagedObject *category;

@end
