//
//  MyCoreBluetoothDemoTests.m
//  MyCoreBluetoothDemoTests
//
//  Created by ljf on 16/5/20.
//  Copyright © 2016年 hanwang. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface MyCoreBluetoothDemoTests : XCTestCase

@end

@implementation MyCoreBluetoothDemoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    NSLog(@"Put setup code here.");
    
    
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    NSLog(@"Put teardown code here.");
    
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSLog(@"This is an example of a functional test case.");
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    NSLog(@"This is an example of a performance test case.");
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
        
        
    }];
}

@end
