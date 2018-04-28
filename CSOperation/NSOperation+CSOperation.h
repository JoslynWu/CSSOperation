//
//  NSOperation+CSOperationAbstract.h
//  CSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperation (CSOperationStart)

- (void)syncStart;
- (void)asyncStart;

- (void)startAfterOperations:(NSOperation *)newOperation, ...;

@end



@interface NSOperationQueue (CSOperationDispatchManager)

/** 立即执行Operation */
+ (void)syncStartOperations:(NSOperation *)newOperation, ...;

/** 并发或异步执行Operation */
+ (void)asyncStartOperations:(NSOperation *)newOperation, ...;

@end

