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
        @synchronized(mArr) {
            [mArr addObject:outsideFlag];
            dispatch_async(dispatch_get_main_queue(), ^{
                CSS_POST_NOTIF
            });
        }
    }];
    
    for (NSInteger i = 0; i < 999; i++) {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            // NSLog(@"--in-->%ld,%@", i, [NSThread currentThread]);
            @synchronized(mArr) {
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

- (void)testAddConditionDependency { // TODO J
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
    NSString *outsideFlag = @"outsideFlag";
    NSString *insideFlag = @"insideFlag";
    CSSOperation *outOp = [CSSOperation new];
    outOp.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
        NSLog(@"--o00000000000000000000000000000000000ut-->%@", @"");
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
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            NSLog(@"--i-->%ld", i);
            [NSThread sleepForTimeInterval:0.01];
            @synchronized(mArr) {
                [mArr addObject:insideFlag];
            };
            maker.finished = YES;
        };
        [ops addObject:op];
        [op asyncStart];
    }
    
    [ops[50] addDependency:ops.lastObject condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
        return YES;
    }];
    [ops[30] addDependency:ops[50] condition:^BOOL(__kindof CSSOperation * _Nonnull maker) {
        return NO;
    }];
    [outOp addDependencyArray:ops.copy];
    [outOp asyncStart];
    
    CSS_WAIT
     NSLog(@"--mArr count-->%ld", mArr.count);
    XCTAssertTrue(mArr.count == opCount + 1);
    XCTAssertTrue([mArr.lastObject isEqualToString:outsideFlag]);
}

- (void)testOperationCancel {
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
    NSInteger cancelCount = 50;
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
        if (i < cancelCount ) {
            [op cancel];
        }
        [op asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue(mArr.count == opCount + 1 - cancelCount);
    XCTAssertTrue([mArr.lastObject isEqualToString:outsideFlag]);
}

- (void)testRemoveDependency {
    NSMutableArray<NSString *> *mArr = [NSMutableArray array];
    NSInteger opCount = 99;
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
        op.name = [NSString stringWithFormat:@"%ld", i];
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            // [NSThread sleepForTimeInterval:0.01];
            @synchronized(mArr) {
                [mArr addObject:insideFlag];
            }
            maker.finished = YES;
        };
        
        if (i > 4 && i < 11) {
            [outOp addDependency:op];
        }
        if (i > 4 && i < 8) {
            [outOp removeDependency:op];
        }
        [op asyncStart];
    }
    [outOp asyncStart];
    
    CSS_WAIT
    XCTAssertTrue(mArr.count <= opCount + 1);
}


@end
