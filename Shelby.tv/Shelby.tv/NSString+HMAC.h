//
//  NSString+HMAC.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/7/13.
//  Copyright (c) 2013 Shelby TV. All rights reserved.
//

@interface NSString (HMAC)

+ (NSString *)stringWithHMACFromDictionary:(NSDictionary *)dictionary;

@end
