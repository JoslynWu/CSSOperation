//
//  CSSConcurrentViewController.m
//  Example
//
//  Created by Joslyn Wu on 2018/5/19.
//  Copyright © 2018年 Joslyn Wu. All rights reserved.
//

#import "CSSConcurrentViewController.h"
#import "CSSOperation.h"

@interface CSSConcurrentViewController ()

@property (weak, nonatomic) IBOutlet UILabel *logLab;
@property (nonatomic, strong) NSMutableString *resultMStr;

@end

@implementation CSSConcurrentViewController

- (void)dealloc {
    NSLog(@"--->%s",__func__);
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.resultMStr = [[NSMutableString alloc] initWithString:@"-------- LOG --------\n\n"];

    for (NSInteger i = 0; i < 12; i++) {
        CSSOperation *op = [CSSOperation new];
        op.name = [NSString stringWithFormat:@"第%ld个operation", i];
        __weak typeof(self) weakSelf = self;
        op.blockOnCurrentThread = ^(__kindof CSSOperation *maker) {
            NSString *str = [NSString stringWithFormat:@">%@, thread:%@\n", maker.name, [NSThread currentThread]];
            NSLog(@"---->%@", str);
            @synchronized(weakSelf.resultMStr) {
                [weakSelf.resultMStr appendString:str];
            }
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                weakSelf.logLab.text = weakSelf.resultMStr;
            }];
        };
        [op asyncStart];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
