//
//  ShelbyAPIClientTests.m
//  Shelby.tv
//
//  Created by Keren Pinkas on 10/14/13.
//  Copyright (c) 2013 Shelby TV, Inc. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ShelbyDataMediator.h"
#import "ShelbyAPIClient.h"
#import "XCTestCase+AsyncTesting.h"


@interface ShelbyAPIClientTests : XCTestCase

@end

@implementation ShelbyAPIClientTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testFetchGlobalChannels
{
    [ShelbyAPIClient fetchGlobalChannelsWithBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        } else {
            XCTAssertNotNil(error, @"Error should not be nil");
            
            [self notify:XCTAsyncTestCaseStatusFailed];
        }
    }];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10];
}

- (void)testLoginUser
{
    [ShelbyAPIClient loginUserWithEmail:@"martha" password:@"kerenios" andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        } else {
            XCTAssertNotNil(error, @"Error should not be nil");
            
            [self notify:XCTAsyncTestCaseStatusFailed];
        }
    }];
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10];
}

- (void)testLoginUserWrongCredentials
{
    [ShelbyAPIClient loginUserWithEmail:@"maxwell" password:@"keren" andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self notify:XCTAsyncTestCaseStatusFailed];
        } else {
            XCTAssertNotNil(error, @"Error should not be nil");
            
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        }
    }];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10];
}

- (void)testFetchUserForNilUserID
{
    [ShelbyAPIClient fetchUserForUserID:nil andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self notify:XCTAsyncTestCaseStatusFailed];
        } else {
            XCTAssertNotNil(error, @"Error should not be nil");
            
            [self notify:XCTAsyncTestCaseStatusFailed];
        }
    }];
    
    [self waitForTimeout:10];
}

- (void)testFetchUserForUserID
{
    [ShelbyAPIClient fetchUserForUserID:@"martha" andBlock:^(id JSON, NSError *error) {
        if (JSON) {
            [self notify:XCTAsyncTestCaseStatusSucceeded];
        } else {
            XCTAssertNotNil(error, @"Error should not be nil");
            
            [self notify:XCTAsyncTestCaseStatusFailed];
        }
    }];
    
    [self waitForStatus:XCTAsyncTestCaseStatusSucceeded timeout:10];
}
@end