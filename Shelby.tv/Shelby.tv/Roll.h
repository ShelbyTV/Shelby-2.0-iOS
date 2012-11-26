//
//  Roll.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/26/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Roll : NSManagedObject

@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;

@end
