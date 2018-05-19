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
@synthesize ready = _ready;

#pragma mark - lifecycle
- (instancetype)init {
    return [self initWithOperationType:kCSSOperationTypeConcurrent];
}

+ (instancetype)operationWithType:(CSSOperationType)type {
    return [[self alloc] initWithOperationType:type];
}

- (instancetype)initWithOperationType:(CSSOperationType)type {
    self = [super init];
    if (!self) {
        return nil;
    }
    _operationType = type;
    return self;
}

#pragma mark - Template Sub Methods
+ (NSOperationQueue *)_queueForOperation:(__kindof NSOperation *)newOperation {
    
    CSSOperation *tempOperation = (CSSOperation *)newOperation;
    CSSOperationType operationType = tempOperation.operationType ?: kCSSOperationTypeConcurrent;
    NSOperationQueue *queue = nil;
    if (tempOperation.queues.count &&
        [tempOperation.queues.allKeys containsObject:operationType] &&
        [tempOperation.queues[operationType] isKindOfClass:[NSOperationQueue class]]){
        queue = tempOperation.queues[operationType];
    } else {
        queue = _CSSOperationManagerGlobalQueue(operationType);
    }
    
    if (queue.operations.count <= 0) {
        tempOperation.ready = YES;
    }
    
    if (operationType == kCSSOperationTypeSingleton) {
        for (NSOperation *operation in [queue operations]) {
            if ([operation isMemberOfClass:self]) {
                queue = nil;
                break;
            }
        }
        
    } else if (operationType == kCSSOperationTypeSerial) {
        [queue.operations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof NSOperation *op, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([op isMemberOfClass:self]) {
                dispatch_block_t userCompletionBlcok = op.completionBlock ?: nil;
                op.completionBlock = ^{
                    !userCompletionBlcok ?: userCompletionBlcok();
                    tempOperation.ready = YES;
                };
                // [tempOperation addDependency:(NSOperation *)op];
                *stop = YES;
            }
        }];
    } else if (operationType == kCSSOperationTypeConcurrent) {
        tempOperation.ready = YES;
    }
    
    return queue;
}

#pragma mark - Pubilc Methods
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

- (void)setReady:(BOOL)ready {
    [self willChangeValueForKey:NSStringFromSelector(@selector(isReady))];
    _ready = ready;
    [self didChangeValueForKey:NSStringFromSelector(@selector(isReady))];
}

@end

