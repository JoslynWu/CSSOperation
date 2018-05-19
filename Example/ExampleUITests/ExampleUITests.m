//
//  ExampleUITests.m
//  ExampleUITests
//
//  Created by Joslyn Wu on 2018/5/4.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface ExampleUITests : XCTestCase

@end

@implementation ExampleUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSingleton {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"伪单例队列"] tap];
    [app.alerts[@"Did Load"].buttons[@"取消"] tap];
    [[[XCUIApplication alloc] init].navigationBars[@"Singleton"].buttons[@"CSSOperation"] tap];
}

- (void)testSerial {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [[[XCUIApplication alloc] init].buttons[@"串行队列"] tap];
    [app.alerts[@"Did Load"].buttons[@"取消"] tap];
    [app.sheets[@"Did Load"].buttons[@"取消"] tap];
    [app.alerts[@"Did Appear"].buttons[@"取消"] tap];
    [app.sheets[@"Did Appear"].buttons[@"取消"] tap];
    [app.navigationBars[@"Serial"].buttons[@"CSSOperation"] tap];
}

- (void)testConcurrent {
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    [app.buttons[@"并发队列"] tap];
    sleep(2.0);
    [app.navigationBars[@"Concurrent"].buttons[@"CSSOperation"] tap];
    
}

@end
