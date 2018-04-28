//
//  BaseOperation.h
//  CSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import <Foundation/Foundation.h>
@class CSBaseOperation;

typedef NSString *CSBaseOperationType;
extern CSBaseOperationType const kCSBaseOperationTypeSingleton;
extern CSBaseOperationType const kCSBaseOperationTypeSerial;
extern CSBaseOperationType const kCSBaseOperationTypeConcurrent;

typedef void (^CSBaseOperationBlock)(CSBaseOperation *make);

@interface CSBaseOperation : NSOperation

@property (assign, nonatomic, getter = isExecuting) BOOL executing;
@property (assign, nonatomic, getter = isFinished) BOOL finished;

@property (nonatomic, copy) CSBaseOperationType operationType;
@property (nonatomic, copy) CSBaseOperationBlock blockOnMainThread;
@property (nonatomic, copy) CSBaseOperationBlock blockOnCurrentThread;

@end

