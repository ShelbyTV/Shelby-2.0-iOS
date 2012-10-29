//
//  CoreDataSingleton.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 10/29/12.
//  Copyright (c) 2012 Arthur Ariel Sabintsev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataSingleton : NSObject

+ (CoreDataSingleton*)sharedInstance;

@end
