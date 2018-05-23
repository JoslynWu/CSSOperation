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
        @synchronized(mArr) {
            [mArr addObject:outsideFlag];
            dispatch_async(dispatch_get_main_queue(), ^{
                CSS_POST_NOTIF
            });
        }
    }];
    
    for (NSInteger i = 0; i < 999; i++) {
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
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

- (void)testAddConditionDependency {
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
