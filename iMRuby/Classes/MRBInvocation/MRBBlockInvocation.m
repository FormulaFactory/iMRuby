//
//  MRBBlockInvocation.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBBlockInvocation.h"


@implementation MRBBlockInvocation

- (id)invokeAndReturn
{
    if (!self.target || !self.sign) {
        return nil;
    }
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:self.sign];
    inv.target = self.target;
    
    [self.arguments enumerateObjectsUsingBlock:^(id  _Nonnull arg, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = idx + 1;
        const char* argType = [self.sign getArgumentTypeAtIndex:index];
        [self setArgument:arg argType:argType index:index inv:inv];
    }];
    [inv invoke];
    
    const char *returnType = self.sign.methodReturnType;
    return [self getReturnValue:returnType inv:inv];
}


@end
