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
        // NSLog(@"--outoutout-->%@,%@", @"outOp", [NSThread currentThread]);
        @synchronized(outsideFlag) {
            [mArr addObject:outsideFlag];
            dispatch_async(dispatch_get_main_queue(), ^{
                CSS_POST_NOTIF
            });
        }
    }];
    
    for (NSInteger i = 0; i < 999; i++) {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            // NSLog(@"--in-->%ld,%@", i, [NSThread currentThread]);
            @synchronized(insideFlag) {
                [mArr addObject:insideFlag];
            }
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
    NSInteger opCount = 999;
    NSString *outsideFlag = @"outsideFlag";
    NSString *insideFlag = @"insideFlag";
    CSSOperation *outOp = [CSSOperation new];
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        @synchronized(outsideFlag) {
            [mArr addObject:outsideFlag];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF
            maker.finished = YES;
        });
    };
    
    for (NSInteger i = 0; i < opCount; i++) {
        CSSOperation *op = [CSSOperation new];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            @synchronized(insideFlag) {
                [mArr addObject:insideFlag];
                maker.finished = YES;
            }
        };
        [outOp addDependency:op];
        [op asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue(mArr.count == opCount + 1);
    XCTAssertTrue([mArr.lastObject isEqualToString:outsideFlag]);
}


@end
