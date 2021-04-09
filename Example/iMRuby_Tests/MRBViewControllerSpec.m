//
//  MRBViewControllerSpec.m
//  iMRuby
//
//  Created by didi on 2021/4/8.
//  Copyright 2021 ping.cao. All rights reserved.
//

#import <Kiwi/Kiwi.h>
#import "MRBViewController.h"
@import iMRuby;

SPEC_BEGIN(MRBViewControllerSpec)

describe(@"Test OC <-> Ruby", ^{
    
    context(@"type conversion", ^{
        
        __block MRBContext *mrbContext;
        beforeAll(^{
            mrbContext = [[MRBContext alloc] init];
        });
                
        it(@"ruby nil -> OC nil or NSNull", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"nil"];
            [[theValue(mrbRet.isNil) should] beYes];
        });
        
        it(@"ruby string -> OC NSString", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"'string'"];
            [[mrbRet.toString should] equal:@"string"];
        });
        
        it(@"ruby symbol -> OC NSString", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@":sym"];
            [[mrbRet.toString should] equal:@"sym"];
        });
        
        it(@"ruby Fixnum -> OC NSNumber", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"999999999"];
            [[mrbRet.toNumber should] equal:@999999999];
        });
        
        it(@"ruby Float -> OC NSNumber", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"0.999999999"];
            [[mrbRet.toNumber should] equal:@0.999999999];
        });
        
        it(@"ruby boolean -> OC NSNumber", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"true"];
            [[mrbRet.toNumber should] equal:@YES];
        });
        
        it(@"ruby Hash -> OC NSDictionary", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"{'width' => 100}"];
            [[mrbRet.toDict should] equal:@{@"width": @100}];
        });
        
        it(@"ruby Array -> OC NSArray", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"['a', 1, true, {'hash' => 'dict'}]"];
            [[mrbRet.toArray should] equal:@[@"a", @1, @YES, @{@"hash": @"dict"}]];
        });
        
        it(@"ruby Time -> OC NSDate", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"Time.at(15000000000)"];
            [[theValue(mrbRet.toDate.timeIntervalSince1970) should] equal:theValue(15000000000)];
        });
        
        it(@"ruby MRBCocoa::Object -> OC NSObject", ^{
            NSObject *obj = [NSObject new];
            [mrbContext registerConst:@"CVObjct" value:obj];
            MRBValue *mrbRet = [mrbContext evaluateScript:@"MRBCocoa::Const::CVObjct"];
            [[mrbRet.toObject should] beKindOfClass:[NSObject class]];
        });
        
        it(@"ruby MRBCocoa::Klass -> OC Class", ^{
            Class klass = NSObject.class;
            [mrbContext registerConst:@"CVKlass" value:klass];
            MRBValue *mrbRet = [mrbContext evaluateScript:@"MRBCocoa::Const::CVKlass"];
            [[mrbRet.toKlass should] beKindOfClass:NSObject.class];
        });
        
        it(@"ruby MRBCocoa::Block -> OC NSBlock", ^{
            NSNumber* (^ocBlock)(void) = ^NSNumber*() {
                return @100;
            };
            [mrbContext registerConst:@"CVBlock" value:ocBlock];
            MRBValue *mrbRet = [mrbContext evaluateScript:@"MRBCocoa::Const::CVBlock.call"];
            [[mrbRet.toNumber should] equal:@100];
        });
        
        it(@"CGPoint", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"{'x'=>0, 'y'=>0}"];
            [[theValue(mrbRet.toPoint) should] equal:theValue(CGPointMake(0, 0))];
        });
        
        it(@"CGSize", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"{'width'=>0, 'height'=>0}"];
            [[theValue(mrbRet.toSize) should] equal:theValue(CGSizeMake(0, 0))];
        });
        
        it(@"CGRect", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"{'x'=>0, 'y'=>0, 'width'=>0, 'height'=>0}"];
            [[theValue(mrbRet.toRect) should] equal:theValue(CGRectMake(0, 0, 0, 0))];
        });
        
        it(@"NSRange", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"{'location'=>0, 'length'=>0}"];
            [[theValue(mrbRet.toRange) should] equal:theValue(NSMakeRange(0, 0))];
        });
    });
    
    context(@"OC call ruby method", ^{
        __block MRBContext *mrbContext;
    
        beforeEach(^{
            mrbContext = [[MRBContext alloc] init];
        });
        
        it(@"shold has a return value that equal param",^{
            [mrbContext evaluateScript:@"def a_method(val); val; end;"];
            MRBValue *mrbVal = [MRBValue valueWithInt64:100 inContext:mrbContext];
            MRBValue *mrbRet = [mrbContext callFunc:@"a_method" args:@[mrbVal]];
            [[theValue(mrbRet.toInt64) should] equal:theValue(100)];
        });
    });
    

});

SPEC_END
