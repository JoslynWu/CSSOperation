//
//  CSSConditionDependency.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/23.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSOperation.h"

@interface CSSConditionDependency : XCTestCase

@end

@implementation CSSConditionDependency

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddSingleConditionDependency {
    NSMutableArray<NSNumber *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
    NSNumber *outsideFlag = @(99 + 1);
    CSSOperation *outOp = [CSSOperation new];
    outOp.name = @"out";
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        @synchronized(mArr) {
            [mArr addObject:outsideFlag];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            CSS_POST_NOTIF
        });
        maker.finished = YES;
    };
    
    NSMutableArray *ops = [NSMutableArray arrayWithCapacity:opCount];
    for (NSInteger i = 0; i < opCount; i++) {
        CSSOperation *op = [CSSOperation new];
        op.name = [NSString stringWithFormat:@"%ld", i];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            // [NSThread sleepForTimeInterval:0.01];
            @synchronized(mArr) {
                [mArr addObject:@(i)];
            };
            maker.finished = YES;
        };
        [ops addObject:op];
    }
    
    [ops[50] addDependency:ops.lastObject condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
        return NO;
    }];
    [ops[30] addDependency:ops[50] condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
        return YES;
    }];
    [outOp addDependencyArray:ops.copy];
    for (CSSOperation *o in ops) {
        [o asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    NSInteger resultCount = opCount + 1 - 1;
    XCTAssertTrue(mArr.count == resultCount);
    for (NSNumber *num in mArr) {
        XCTAssertTrue(num.integerValue != 50);
    }
    XCTAssertTrue(mArr[resultCount - 2].integerValue == 30);
    XCTAssertTrue(mArr.lastObject == outsideFlag);
}

//- (void)testAddMultiConditionDependency {
//    NSMutableArray<NSNumber *> *mArr = [NSMutableArray array];
//    NSInteger opCount = 99;
//    NSNumber *outsideFlag = @(99 + 1);
//    CSSOperation *outOp = [CSSOperation new];
//    outOp.name = @"out";
//    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
//        @synchronized(mArr) {
//            [mArr addObject:outsideFlag];
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            CSS_POST_NOTIF
//        });
//        maker.finished = YES;
//    };
//
//    NSMutableArray<CSSOperation *> *ops = [NSMutableArray arrayWithCapacity:opCount];
//    for (NSInteger i = 0; i < opCount; i++) {
//        CSSOperation *op = [CSSOperation new];
//        op.name = [NSString stringWithFormat:@"%ld", i];
//        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
//            if ([maker.name isEqualToString:@"1"]) {
//                [NSThread sleepForTimeInterval:1];
//            }
//            NSLog(@"---->%ld", i);
//            @synchronized(mArr) {
//                [mArr addObject:@(i)];
//            };
//            maker.finished = YES;
//        };
//        [ops addObject:op];
//    }
//    [ops.lastObject addDependency:ops[20]];
//    [ops[50] addDependency:ops.lastObject condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
//        return NO;
//    }];
//    [ops[50] addDependency:ops[1]];
//    [ops[30] addDependency:ops[50] condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
//        return YES;
//    }];
//
//    [outOp addDependencyArray:ops.copy];
//    for (CSSOperation *o in ops) {
//        [o asyncStart];
//    }
//    [outOp asyncStart];
//
//    CSS_WAIT
//    NSInteger resultCount = opCount + 1 - 1;
//    XCTAssertTrue(mArr.count == resultCount);
//    for (NSNumber *num in mArr) {
//        XCTAssertTrue(num.integerValue != 50);
//    }
//    XCTAssertTrue(mArr[resultCount - 2].integerValue == 30);
//    XCTAssertTrue(mArr.lastObject == outsideFlag);
//}

@end
