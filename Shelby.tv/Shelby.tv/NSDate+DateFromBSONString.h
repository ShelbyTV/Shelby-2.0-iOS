//
//  NSDate+DateFromBSONString.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 5/24/12.
//  Copyright (c) 2012 Shelby.tv. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (DateFromBSONString)

+ (NSDate*)dataFromBSONstring:(NSString*)string;

@end
