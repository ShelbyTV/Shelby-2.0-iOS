//
//  NSString+HMAC.h
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

@interface NSString (HMAC)

+ (NSString *)generateHMACFromData:(NSData *)data;

@end
