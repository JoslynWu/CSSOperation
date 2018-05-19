//
//  CSSSingletonViewController.m
//  Example
//
//  Created by Joslyn Wu on 2018/5/19.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSSingletonViewController.h"
#import "CSSOperation.h"

@interface CSSSingletonViewController ()

@end

@implementation CSSSingletonViewController

- (void)dealloc {
    NSLog(@"--->%s",__func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self alertWithTitle:@"Did Load" message:@"00000" count:2];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self alertWithTitle:@"Did Appear" message:@"message" count:2];
}

- (void)alertWithTitle:(NSString *)title message:(NSString *)msg count:(NSInteger)count {
    for (NSInteger i = 0; i < count; i++) {
        UIAlertControllerStyle alertStyle = (i % 2 == 0) ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet;
        CSSOperation *operation = [CSSOperation operationWithType:kCSSOperationTypeSingleton];
        __weak typeof(self) weakSelf = self;
        operation.blockOnMainThread = ^(CSSOperation *make){
            UIAlertController *alertCtl = [UIAlertController alertControllerWithTitle:title message:msg preferredStyle:alertStyle];
            [alertCtl addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                make.finished = YES;
                make.executing = NO;
            }]];
            [weakSelf.navigationController presentViewController:alertCtl animated:YES completion:nil];
        };
        [operation asyncStart];
    }
}

@end
