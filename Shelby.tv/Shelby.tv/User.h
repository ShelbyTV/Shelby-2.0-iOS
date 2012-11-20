//
//  User.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 11/20/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * queueID;
@property (nonatomic, retain) NSString * rollID;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * userImage;

@end
