//
//  NextViewController.m
//  CSSOperation
//
//  Created by Joslyn Wu on 2018/4/17.
//  Copyright © 2018年 joslyn. All rights reserved.
//

#import "NextViewController.h"
#import "CSSOperation.h"
#import "NSOperation+CSSOperation.h"

@interface NextViewController ()

@end

@implementation NextViewController

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
        CSSOperation *operation = [[CSSOperation alloc] initWithOperationType:kCSSOperationTypeSerial];
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
