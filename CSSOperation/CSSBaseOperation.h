//
//  BaseOperation.h
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CSSBaseOperation;

typedef NSString *CSSBaseOperationType;
extern CSSBaseOperationType const kCSSBaseOperationTypeSingleton;
extern CSSBaseOperationType const kCSSBaseOperationTypeSerial;
extern CSSBaseOperationType const kCSSBaseOperationTypeConcurrent;

typedef void (^CSSBaseOperationBlock)(CSSBaseOperation *make);

@interface CSSBaseOperation : NSOperation

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@property (nonatomic, copy) CSSBaseOperationType operationType;
@property (nonatomic, copy) CSSBaseOperationBlock blockOnMainThread;
@property (nonatomic, copy) CSSBaseOperationBlock blockOnCurrentThread;

@end

