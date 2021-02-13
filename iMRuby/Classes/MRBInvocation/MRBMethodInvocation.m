//
//  MRBMethodInvocation.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBMethodInvocation.h"
#import <UIKit/UIKit.h>

@implementation MRBMethodInvocation

- (id)invokeAndReturn
{
    if (!self.target || !self.sign || !self.selector) {
        return nil;
    }
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:self.sign];
    inv.target = self.target;
    inv.selector = self.selector;
    
    [self.arguments enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = idx + 2;
        const char* argType = [self.sign getArgumentTypeAtIndex:index];
        [self setArgument:arg argType:argType index:index inv:inv];
    }];
    [inv invoke];
    
    const char *returnType = self.sign.methodReturnType;
    return [self getReturnValue:returnType inv:inv];
}

@end
