//
//  NSOperation+CSOperationAbstract.m
//  CSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "NSOperation+CSOperation.h"

static dispatch_queue_t _CSOperationDispatchManagerSerialQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("com.CSOpationManager.NSOperationManagerSerialQueue", DISPATCH_QUEUE_SERIAL);
    });
    
    return queue;
}

@interface NSOperation (_CSOperationManagerTemplate)

+ (void)_asyncStartOperation:(NSOperation *)newOperation;

@end

@implementation NSOperation (_CSOperationManagerTemplate)

#pragma mark - Template Method
+ (void)_asyncStartOperation:(NSOperation *)newOperation {
    // 检测newOperation是否已被处理
    if (![self _operationDidHandle:newOperation]) {
        NSOperationQueue *queue = [self _queueForOperation:newOperation];
        queue ? [queue addOperation:newOperation] : [newOperation cancel];
    }
}

#pragma mark - Template Sub Methods
#pragma mark -自行处理Operation
+ (BOOL)_operationDidHandle:(NSOperation *)newOperation {
    return NO;
}

#pragma mark -当前OperationQueue
+ (NSOperationQueue *)_queueForOperation:(NSOperation *)newOperation {
    return nil;
}

@end



@implementation NSOperation (CSOperationStart)

- (void)syncStart {
    [NSOperationQueue syncStartOperations:self, nil];
}

- (void)asyncStart {
    [NSOperationQueue asyncStartOperations:self, nil];
}

- (void)startAfterOperations:(NSOperation *)newOperation, ... {
    NSMutableArray *operations = [NSMutableArray array];
    [operations addObject:newOperation];
    
    va_list argumentList;
    va_start(argumentList, newOperation);
    
    NSOperation *eachOperation = nil;
    
    while((eachOperation = va_arg(argumentList, NSOperation *))) {
        [operations addObject:eachOperation];
    }
    
    va_end(argumentList);
    
    for (NSOperation *operation in operations) {
        [self addDependency:operation];
    }
}

@end



@implementation NSOperationQueue (CSOperationDispatchManager)

#pragma mark -Sync
+ (void)syncStartOperations:(NSOperation *)newOperation, ... {
    if (newOperation) {
        [newOperation start];
        
        va_list argumentList;
        va_start(argumentList, newOperation);
        
        NSOperation *eachOperation = nil;
        
        while((eachOperation = va_arg(argumentList, NSOperation *))) {
            [eachOperation start];
        }
        
        va_end(argumentList);
    }
}

#pragma mark - Async
+ (void)asyncStartOperations:(NSOperation *)newOperation, ... {
    if (newOperation) {
        NSMutableArray *operations = [NSMutableArray array];
        [operations addObject:newOperation];
        
        va_list argumentList;
        va_start(argumentList, newOperation);
        
        NSOperation *eachOperation = nil;
        
        while((eachOperation = va_arg(argumentList, NSOperation *))) {
            [operations addObject:eachOperation];
        }
        
        va_end(argumentList);
        
        dispatch_async(_CSOperationDispatchManagerSerialQueue(), ^{
            
            for (NSOperation *operation in operations) {
                [operation.class _asyncStartOperation:operation];
            }
        });
    }
}

@end

