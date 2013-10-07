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
    self.supportedTest = @{kShelbyABTestNotification : [self notificationDictionaryWithName:@"Default" day:@"2" time:@"8" andMessage:@"hi"]};
    
    [self fetchABTests];
}

- (void)fetchABTests
{
    [ShelbyAPIClient fetchABTestWithBlock:^(id JSON, NSError *error) {
        if (!JSON || error) {
            [self setDefaultValuesForAllTests];
        } else {
            [self setupTestWithJSON:JSON];
        }
    }];
}

- (NSDictionary *)dictionaryForTest:(NSString *)testName
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:testName];
}

- (void)setDefaultValuesForAllTests
{
    [self setTestName:kShelbyABTestNotification withDictionary:[self defaultDictionaryForTest:kShelbyABTestNotification]];
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

- (NSDictionary *)defaultDictionaryForTest:(NSString *)testName
{
    return [self.supportedTest objectForKey:testName];
}

- (void)setTestName:(NSString *)name withDictionary:(NSDictionary *)dictionary
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

- (void)setupTestWithJSON:(id)JSON
{
    if ([JSON isKindOfClass:[NSDictionary class]]) {
        NSArray *tests = JSON[@"result"];
        if (!tests || ![tests isKindOfClass:[NSArray class]]) {
            [self setTestName:kShelbyABTestNotification withDictionary:[self defaultDictionaryForTest:kShelbyABTestNotification]];
            return;
        }
        
        for (NSDictionary *test in tests) {
            if (test  && [test isKindOfClass:[NSDictionary class]]) {
                NSString *testName = test[@"name"];
                if (![self isSupportedTest:testName]) {
                    continue;
                }

                NSArray *buckets = test[@"buckets"];

                NSDictionary *currentActiveTest = [self dictionaryForTest:testName];
                NSString *selectedBucket = nil;
                if (currentActiveTest && [self isTestStillActive:currentActiveTest[kShelbyABTestBucketName] availableTests:buckets]) {
                    // Test still active, use defaults
                    selectedBucket = currentActiveTest[kShelbyABTestBucketName];
                } else {
                    NSDictionary *bucketValue = [self pickABucket:buckets];
                    if (!bucketValue) {
                        bucketValue = [self defaultDictionaryForTest:testName];
                    }
                    selectedBucket = bucketValue[kShelbyABTestBucketName];
                    [self setTestName:testName withDictionary:bucketValue];
                }

                if ([testName isEqualToString:kAnalyticsABTestRetention]) {
                    [ShelbyAnalyticsClient sendEventWithCategory:kAnalyticsCategoryABTest action:kAnalyticsABTestRetention label:selectedBucket];
                }
            }
        }
    }
}
                    
        
- (BOOL)isTestStillActive:(NSString *)bucketName availableTests:(NSArray *)buckets
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
