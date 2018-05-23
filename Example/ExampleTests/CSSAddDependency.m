//
//  CSSAddDependency.m
//  ExampleTests
//
//  Created by Joslyn Wu on 2018/5/23.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "CSSUnitTestDefine.h"
#import "CSSOperation.h"

@interface CSSAddDependency : XCTestCase

@end

@implementation CSSAddDependency

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddDependency {
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSInteger opCount = 999;
    NSString *outsideFlag = @"outsideFlag";
    NSString *insideFlag = @"insideFlag";
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
                [mArr addObject:insideFlag];
            };
            maker.finished = YES;
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
