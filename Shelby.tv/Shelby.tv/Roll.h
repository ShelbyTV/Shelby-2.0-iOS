//
//  Roll.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/5/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Frame;

@interface Roll : NSManagedObject

@property (nonatomic, retain) NSString * displayThumbnailURL;
@property (nonatomic, retain) NSString * creatorID;
@property (nonatomic, retain) NSNumber * frameCount;
@property (nonatomic, retain) NSNumber * isCategory;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) Frame *frame;

@end
