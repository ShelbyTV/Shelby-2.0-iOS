//
//  User.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 2/20/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * admin;
@property (nonatomic, retain) NSString * likesRollID;
@property (nonatomic, retain) NSString * nickname;
@property (nonatomic, retain) NSString * personalRollID;
@property (nonatomic, retain) NSString * token;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSString * userImage;
@property (nonatomic, retain) NSNumber * twitterConnected;
@property (nonatomic, retain) NSNumber * facebookConnected;

@end
