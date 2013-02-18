//
//  Channel.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/18/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Channel : NSManagedObject

@property (nonatomic, retain) NSString * channelID;
@property (nonatomic, retain) NSString * displayDescription;
@property (nonatomic, retain) NSString * displayTitle;
@property (nonatomic, retain) NSString * displayThumbnailURL;

@end
