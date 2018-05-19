//
//  ExampleTests.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/19.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSOperation.h"

@interface ExampleTests : XCTestCase

@end

@implementation ExampleTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBlockOperation {
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSString *outsideFlag = @"outsideFlag";
    NSString *insideFlag = @"insideFlag";
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *outOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"--outoutout-->%@,%@", @"outOp", [NSThread currentThread]);
        [mArr addObject:outsideFlag];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF;
        });
    }];
    
    for (NSInteger i = 0; i < 100; i++) {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"--in-->%ld,%@", i, [NSThread currentThread]);
            [mArr addObject:insideFlag];
        }];
        [outOp addDependency:op];
        [queue addOperation:op];
    }
    [queue addOperation:outOp];
    
    CSS_WAIT
    XCTAssertTrue([mArr.lastObject isEqualToString:outsideFlag]);
}

- (void)testCSSOperation {
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSString *outsideFlag = @"outsideFlag";
    NSString *insideFlag = @"insideFlag";
    CSSOperation *outOp = [CSSOperation new];
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        NSLog(@"--outoutout-->%@,%@", @"outOp", [NSThread currentThread]);
        [mArr addObject:outsideFlag];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF;
        });
    };
    
    for (NSInteger i = 0; i < 100; i++) {
        CSSOperation *op = [CSSOperation new];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            sleep(1);
            NSLog(@"--in-->%ld,%@", i, [NSThread currentThread]);
            [mArr addObject:insideFlag];
        };
        [outOp addDependency:op];
        [op asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue([mArr.lastObject isEqualToString:outsideFlag]);
}


@end
