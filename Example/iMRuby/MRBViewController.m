//
//  MRBViewController.m
//  iMRuby
//
//  Created by ping.cao on 02/13/2021.
//  Copyright (c) 2021 ping.cao. All rights reserved.
//

#import "MRBViewController.h"
@import iMRuby;

@interface Person : NSObject
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;
- (NSString *)__say_something:(NSString *)message;
- (void)coding:(NSString *)code finished:(BOOL(^)(NSString *name, int age))finished;
@end
@implementation Person
- (NSString *)__say_something:(NSString *)message
{
    NSLog(@"%@", message);
    return [self.name stringByAppendingString:message];
}
- (void)coding:(NSString *)code finished:(BOOL(^)(NSString *name, int age))finished
{
    NSLog(@"I am coding %@", code);
    if (finished) {
        BOOL f = finished(self.name, self.age);
        NSLog(@"Block return value: %@", @(f));
    }
}
@end

@interface MRBViewController ()

@property (nonatomic, strong) MRBContext *context;

@end

@implementation MRBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 执行view.rb
    NSString *scriptPath = [[NSBundle mainBundle] pathForResource:@"view" ofType:@"rb"];
    NSString *script = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];
    self.context = [[MRBContext alloc] init];
    self.context.exceptionHandler = ^(NSError * _Nonnull exception) {
        NSLog(@"%@", exception.userInfo[@"msg"]);
    };
    [self.context evaluateScript:script];
    MRBValue *superView = [MRBValue valueWithObject:self.view inContext:self.context];
    [self.context callFunc:@"create_view" args:@[superView]];
    
    // evaluateScript
    [self.context evaluateScript:@"puts \"Happy Niu year!\""];
    
    // exception
   // [self.context evaluateScript:@"happy_nui_year(2021)"];
    
    // 注册Const给ruby使用
//    [self.context registerConst:@"Niu" value:@"Happy Niu year!"];
//    [self.context evaluateScript:@"puts MRBCocoa::Const::Niu"];

    // 注册方法
//    [self.context registerFunc:@"happy_niu_year" block:^NSInteger(int a, int b){
//        NSLog(@"start...");
//        int sum = a + b;
//        NSLog(@"finish...");
//        return sum;
//    }];
//    MRBValue *sum = [self.context evaluateScript:@"MRBCocoa.happy_niu_year(2020,1)"];
//    NSInteger niu_year = sum.toInt64;
//    NSLog(@"%@", @(niu_year));
    
    // 下标注册常量或者方法
    self.context[@"Niu"] = @"Happy Niu year!";
    self.context[@"happy_niu_year"] = ^NSInteger(int a, int b) {
        NSLog(@"start...");
        int sum = a + b;
        NSLog(@"finish...");
        return sum;
    };
    MRBValue *sum = [self.context evaluateScript:@"puts MRBCocoa::Const::Niu;MRBCocoa.happy_niu_year(2020,1)"];
    NSInteger niu_year = sum.toInt64;
    NSLog(@"%@", @(niu_year));
    
    NSString *demoScriptPath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"rb"];
    NSString *demoScript = [NSString stringWithContentsOfFile:demoScriptPath encoding:NSUTF8StringEncoding error:nil];
    [self.context evaluateScript:demoScript];
}

@end
