//
//  NSDate+Extension.h
//  Shelby.tv
//
//  Created by Daniel Spinosa on 9/12/13.
//  Copyright (c) 2013 Shelby.tv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Extension)

+ (NSDate *)dateFromBSONObjectID:(NSString *)identifier;

- (NSString *)prettyRelativeTime;

@end
