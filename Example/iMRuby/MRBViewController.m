//
//  MRBViewController.m
//  iMRuby
//
//  Created by ping.cao on 02/13/2021.
//  Copyright (c) 2021 ping.cao. All rights reserved.
//

#import "MRBViewController.h"
@import iMRuby;

int sumx(int a, int b) {
    int c = a + b;
    return c;
}

@interface Person()
@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) int age;

@end
@implementation Person

- (NSString *)saySth:(NSString *)message
{
    return message;
}

- (NSString *)say_sth:(NSString *)message
{
    return message;
}

- (NSString *)__say_something:(NSString *)message
{
    return message;
}
- (NSString *)finished:(NSString*(^)(NSString *name, int age))finished
{
    NSString *f = finished(self.name, self.age);
    return [@"hi," stringByAppendingString:f];
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
    
    [self.context registerConst:@"Target" value:self];
    [self.context evaluateScript:script];
    MRBValue *superView = [MRBValue valueWithObject:self.view inContext:self.context];
    [self.context callFunc:@"create_view" args:@[superView]];
    
}

- (void)touchAction:(id)sender
{
    [self.context evaluateScript:@"showAlertView"];
}

@end

