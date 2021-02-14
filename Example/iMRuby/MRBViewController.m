//
//  MRBViewController.m
//  iMRuby
//
//  Created by ping.cao on 02/13/2021.
//  Copyright (c) 2021 ping.cao. All rights reserved.
//

#import "MRBViewController.h"
@import iMRuby;

@interface MRBViewController ()

@property (nonatomic, strong) MRBContext *context;

@end

@implementation MRBViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.context = [[MRBContext alloc] init];
    MRBValue *value = [self.context evaluateScript:@"a = \"I am from ruby\""];
    NSString *string = value.toString;
    NSLog(@"%@", string);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
