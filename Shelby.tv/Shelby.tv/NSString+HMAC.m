//
//  NSString+HMAC.m
//  Shelby.tv
//
//  Created by Arthur Ariel Sabintsev on 3/7/13.
//  Copyright (c) 2013 Arthur Ariel Sabintsev. All rights reserved.
//

#define kHMACKey    @"HMACKey"

#include <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

@implementation NSString (HMAC)

+ (NSString *)stringWithHMACFromDictionary:(NSDictionary *)dictionary
{
    
    NSString *dataString = [NSString stringWithFormat:@"%@", dictionary];
    const char *cData = [dataString cStringUsingEncoding:NSASCIIStringEncoding];
    
    NSString *key = kHMACKey;
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA256_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA256, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    
    // description converts to hex but puts <> around it and spaces every 4 bytes
    NSString *hash = [HMAC description];
    hash = [hash stringByReplacingOccurrencesOfString:@" " withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@"<" withString:@""];
    hash = [hash stringByReplacingOccurrencesOfString:@">" withString:@""];

    return hash;
}

@end
