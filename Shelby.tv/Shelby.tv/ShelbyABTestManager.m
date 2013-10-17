//
//  ShelbyABTestManager.m
//  Shelby.tv
//
//  Created by Keren on 9/30/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import "ShelbyABTestManager.h"
#import "ShelbyAPIClient.h"
#import "ShelbyAnalyticsClient.h"

NSString * const kShelbyABTestBucketName = @"name";
NSString * const kShelbyABTestBucketActive = @"active";
NSString * const kShelbyABTestNotification = @"retention1.0";
NSString * const kShelbyABTestNotificationTime = @"time";
NSString * const kShelbyABTestNotificationDay = @"day";
NSString * const kShelbyABTestNotificationMessage = @"message";

@interface ShelbyABTestManager()
@property (nonatomic, strong) NSDictionary *supportedTest;
@end

@implementation ShelbyABTestManager

+ (ShelbyABTestManager *)sharedInstance
{
    static ShelbyABTestManager *sharedInstance = nil;
    static dispatch_once_t modelToken = 0;
    dispatch_once(&modelToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
    });
    
    return sharedInstance;
}

- (void)startABTestManager
{
    // Adding all supported tests
    // TODO: KP KP: choose one of the buckets and manually set as defaults
    // If we change this message to not require 3 nicknames, make sure to modify this: performBackgroundFetchWithCompletionHandler
    self.supportedTest = @{kShelbyABTestNotification : [self notificationDictionaryWithName:@"Default" day:@"1" time:@"1000" andMessage:@"Yes! Videos from %@, %@, %@ and more!"]};
    
    [self fetchABTests];
}

- (void)fetchABTests
{
    [ShelbyAPIClient fetchABTestWithBlock:^(id JSON, NSError *error) {
        if (!JSON || error) {
            [self setDefaultValuesForAllTests];
        } else {
            [self setupTestsWithJSON:JSON];
        }
    }];
}

- (NSDictionary *)activeBucketForTest:(NSString *)testName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:testName];
}

- (void)setDefaultValuesForAllTests
{
    [self setActiveBucket:[self defaultBucketForTest:kShelbyABTestNotification] forTestName:kShelbyABTestNotification];
}

- (NSDictionary *)notificationDictionaryWithName:(NSString *)name day:(NSString *)day time:(NSString *)time andMessage:(NSString *)message
{
    return @{kShelbyABTestBucketName : name,
             kShelbyABTestNotificationTime : @([time integerValue]),
             kShelbyABTestNotificationDay : @([day integerValue]),
             kShelbyABTestNotificationMessage : message};
}

- (BOOL)isSupportedTest:(NSString *)testName
{
    return [self.supportedTest objectForKey:testName] == nil ? NO : YES;
}

- (NSDictionary *)defaultBucketForTest:(NSString *)testName
{
    return [self.supportedTest objectForKey:testName];
}

- (void)setActiveBucket:(NSDictionary *)dictionary forTestName:(NSString *)name
{
    if ([name isEqualToString:kShelbyABTestNotification]) {
        NSDictionary *defaultValues = self.supportedTest[kShelbyABTestNotification];
        NSString *day = dictionary[kShelbyABTestNotificationDay];
        NSString *time = dictionary[kShelbyABTestNotificationTime];
        NSString *message = dictionary[kShelbyABTestNotificationMessage];
        NSString *bucketName = dictionary[kShelbyABTestBucketName];
  
        NSDictionary *bucketDictionary = nil;
        if (!bucketName || !day || !time || !message) {
            bucketDictionary = defaultValues;
        } else {
            bucketDictionary = [self notificationDictionaryWithName:bucketName day:day time:time andMessage:message];
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:bucketDictionary forKey:name];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setupTestsWithJSON:(id)JSON
{
    if ([JSON isKindOfClass:[NSDictionary class]]) {
        NSArray *tests = JSON[@"result"];
        if (!tests || ![tests isKindOfClass:[NSArray class]]) {
            [self setDefaultValuesForAllTests];
            return;
        }
        
        for (NSDictionary *test in tests) {
            if (test  && [test isKindOfClass:[NSDictionary class]]) {
                NSString *testName = test[@"name"];
                if (![self isSupportedTest:testName]) {
                    continue;
                }

                NSArray *buckets = test[@"buckets"];

                NSDictionary *currentActiveBucketForTest = [self activeBucketForTest:testName];
                NSString *selectedBucketName = nil;
                if (currentActiveBucketForTest && [self isBucketStillActive:currentActiveBucketForTest[kShelbyABTestBucketName] availableBuckets:buckets]) {
                    // Test still active, use currently active
                    selectedBucketName = currentActiveBucketForTest[kShelbyABTestBucketName];
                } else {
                    NSDictionary *bucketValue = [self pickABucket:buckets];
                    if (!bucketValue) {
                        bucketValue = [self defaultBucketForTest:testName];
                    }
                    selectedBucketName = bucketValue[kShelbyABTestBucketName];
                    [self setActiveBucket:bucketValue forTestName:testName];
                }

                [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryABTest action:testName label:selectedBucketName];
            }
        }
    }
}
                    
        
- (BOOL)isBucketStillActive:(NSString *)bucketName availableBuckets:(NSArray *)buckets
{
    if (buckets && [buckets isKindOfClass:[NSArray class]]) {
        for (NSDictionary *bucket in buckets) {
            if (!bucket || ![bucket isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            if ([bucket[kShelbyABTestBucketName] isEqualToString:bucketName]) {
                if (bucket[kShelbyABTestBucketActive]) {
                    return YES;
                }
            }
        }
    }

    return NO;
}


- (NSDictionary *)pickABucket:(NSArray *)buckets
{
    if (!buckets || ![buckets isKindOfClass:[NSArray class]]) {
        return nil;
    }

    NSMutableArray *activeBuckets = [@[] mutableCopy];
    for (NSDictionary *bucket in buckets) {
        if (!bucket || ![bucket isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        
        if (!bucket[@"active"]) {
            continue;
        }
        
        [activeBuckets addObject:bucket];
    }
    
    NSUInteger count = [activeBuckets count];
    if (count > 0) {
        return activeBuckets[arc4random_uniform(count)];
    } else {
        return nil;
    }
}

@end
