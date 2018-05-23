//
//  CSSCancel.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/23.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSOperation.h"

@interface CSSCancel : XCTestCase

@end

@implementation CSSCancel

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testOperationCancelBeforeDependecy {
    NSMutableArray<NSNumber *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
    NSInteger cancelCount = 50;
    NSNumber *outsideFlag = @(-11111);
    CSSOperation *outOp = [CSSOperation new];
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        @synchronized(mArr) {
            [mArr addObject:outsideFlag];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF
        });
        maker.finished = YES;
    };
    
    for (NSInteger i = 0; i < opCount; i++) {
        CSSOperation *op = [CSSOperation new];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            @synchronized(mArr) {
                [mArr addObject:@(i)];
            };
            maker.finished = YES;
        };
        if (i < cancelCount ) {
            [op cancel];
        }
        [outOp addDependency:op];
        [op asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue(mArr.count == opCount + 1 - cancelCount);
    for (NSNumber *num in mArr) {
        if (num != outsideFlag) {
            XCTAssertTrue(num.integerValue >= cancelCount);
        }
    }
    XCTAssertTrue(mArr.lastObject == outsideFlag);
}

- (void)testOperationCancelAfterDependecy {
    NSMutableArray<NSNumber *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
    NSInteger cancelCount = 50;
    NSNumber *outsideFlag = @(-11111);
    CSSOperation *outOp = [CSSOperation new];
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        
        @synchronized(mArr) {
            [mArr addObject:outsideFlag];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF
        });
        maker.finished = YES;
    };
    
    for (NSInteger i = 0; i < opCount; i++) {
        CSSOperation *op = [CSSOperation new];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            @synchronized(mArr) {
                [mArr addObject:@(i)];
            };
            maker.finished = YES;
        };
        [outOp addDependency:op];
        [op asyncStart];
        if (i < cancelCount ) {
            [op cancel];
        }
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue(mArr.count == opCount + 1 - cancelCount);
    for (NSNumber *num in mArr) {
        if (num != outsideFlag) {
            XCTAssertTrue(num.integerValue >= cancelCount);
        }
    }
    XCTAssertTrue(mArr.lastObject == outsideFlag);
}

@end
