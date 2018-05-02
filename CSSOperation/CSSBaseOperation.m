//
//  BaseOperation.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "CSSBaseOperation.h"
#import <pthread/pthread.h>

CSSBaseOperationType const kCSSBaseOperationTypeSingleton = @"CSSBaseOperationTypeSingleton";
CSSBaseOperationType const kCSSBaseOperationTypeSerial = @"CSSBaseOperationTypeSerial";
CSSBaseOperationType const kCSSBaseOperationTypeConcurrent = @"CSSBaseOperationTypeConcurrent";

static NSOperationQueue *_CSSOperationManagerQueue(CSSBaseOperationType type) {
    static NSMutableDictionary *queues = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        queues = [NSMutableDictionary dictionary];
    });
    
    NSOperationQueue *queue = queues[type];
    if (!queue) {
        queue = [NSOperationQueue new];
        queue.name = type;
        queues[type] = queue;
    }
    
    return queue;
}

@implementation CSSBaseOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - Template Sub Methods
+ (NSOperationQueue *)_queueForOperation:(NSOperation *)newOperation {
    
    CSSBaseOperation *tempOperation = (CSSBaseOperation *)newOperation;
    CSSBaseOperationType operationType = tempOperation.operationType ?: kCSSBaseOperationTypeConcurrent;
    NSOperationQueue *queue = _CSSOperationManagerQueue(operationType);
    
    if (operationType == kCSSBaseOperationTypeSingleton) {
        for (NSOperation *operation in [queue operations]) {
            if ([operation isMemberOfClass:self]) {
                queue = nil;
                break;
            }
        }
    }
    else if (operationType == kCSSBaseOperationTypeSerial) {
        [queue.operations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isMemberOfClass:self]) {
                [tempOperation addDependency:(NSOperation *)obj];
                *stop = YES;
            }
        }];
    }
    
    return queue;
}

#pragma mark - Pubilc Methods
- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    CSSBaseOperationBlock block = self.blockOnMainThread;
    if (block) {
        if (pthread_main_np()) {
            block(self);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(self);
            });
        }
    } else {
        block = self.blockOnCurrentThread;
        !block ?: block(self);
    }
}

- (void)cancel {
    [super cancel];
    self.finished = YES;
    self.executing = NO;
}

#pragma mark - Set
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:@"isFinished"];
    _finished = finished;
    [self didChangeValueForKey:@"isFinished"];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:@"isExecuting"];
    _executing = executing;
    [self didChangeValueForKey:@"isExecuting"];
}

@end

