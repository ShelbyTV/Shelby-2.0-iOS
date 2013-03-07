//
//  NSString+HMAC.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation NSString (HMAC)

+ (NSString *)generateHMACFromData:(NSData *)data
{
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSString *key;
    
    const char *cData = [dataString cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
   
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC
                                          length:sizeof(cHMAC)];
    
    NSString *hash = [HMAC base64Encoding];
}

@end
