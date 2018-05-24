//
//  BaseOperation.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "CSSOperation.h"

CSSOperationType const kCSSOperationTypeSingleton = @"CSSOperationTypeSingleton";
CSSOperationType const kCSSOperationTypeSerial = @"CSSOperationTypeSerial";
CSSOperationType const kCSSOperationTypeConcurrent = @"CSSOperationTypeConcurrent";

static NSOperationQueue *_CSSOperationManagerGlobalQueue(CSSOperationType type) {
    static NSMutableDictionary *globalQueues = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        globalQueues = [NSMutableDictionary dictionary];
    });
    
    NSOperationQueue *queue = globalQueues[type];
    if (!queue) {
        queue = [NSOperationQueue new];
        queue.name = type;
        globalQueues[type] = queue;
    }
    
    return queue;
}

@implementation CSSOperation

@synthesize executing = _executing;
@synthesize finished = _finished;

#pragma mark - lifecycle
- (instancetype)init {
    return [self initWithType:kCSSOperationTypeConcurrent queue:nil];
}

+ (instancetype)operationWithType:(CSSOperationType)type {
    return [[self alloc] initWithType:type queue:nil];
}

+ (instancetype)operationWithType:(CSSOperationType)type
                            queue:(nullable NSDictionary<CSSOperationType, __kindof NSOperationQueue *> *)queues {
    return [[self alloc] initWithType:type queue:queues];
}

- (instancetype)initWithType:(CSSOperationType)type
                       queue:(nullable NSDictionary<CSSOperationType, __kindof NSOperationQueue *> *)queues {
    self = [super init];
    if (!self) {
        return nil;
    }
    _type = type;
    _queues = queues;
    return self;
}

#pragma mark - private
+ (NSOperationQueue *)_queueForOperation:(__kindof CSSOperation *)newOperation {
    
    CSSOperationType type = newOperation.type;
    if (type.length <= 0) {
        return nil;
    }
    
    NSOperationQueue *queue = newOperation.currentQueue;
    if (type == kCSSOperationTypeSingleton) {
        for (NSOperation *operation in [queue operations]) {
            if ([operation isMemberOfClass:self]) {
                queue = nil;
                break;
            }
        }
        
    } else if (type == kCSSOperationTypeSerial) {
        [queue.operations enumerateObjectsWithOptions:NSEnumerationReverse
                                           usingBlock:
         ^(__kindof NSOperation *op, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([op isMemberOfClass:self]) {
                [newOperation addDependency:op];
                *stop = YES;
            }
        }];
    }
    return queue;
}

#pragma mark - super methods
- (void)start {
    if ([self isCancelled]) {
        self.finished = YES;
        return;
    }
    
    CSSOperationBlock block = self.blockOnMainThread;
    if (block) {
        if ([NSThread currentThread].isMainThread) {
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
    self.executing = NO;
    self.finished = YES;
}

#pragma mark - Set
- (void)setFinished:(BOOL)finished {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    _finished = finished;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
}

- (void)setExecuting:(BOOL)executing {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    _executing = executing;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
}

#pragma mark - ********************* public *********************
- (__kindof NSOperationQueue *)currentQueue {
    CSSOperationType type = self.type;
    
    if (self.queues.count && [self.queues.allKeys containsObject:type] &&
        [self.queues[type] isKindOfClass:[NSOperationQueue class]]){
        return self.queues[type];
    }
    
    return _CSSOperationManagerGlobalQueue(type);;
}

@end

