#import <Kiwi/Kiwi.h>
#import "MRBViewController.h"
@import iMRuby;

SPEC_BEGIN(MRBViewControllerSpec)

describe(@"Test OC <-> Ruby", ^{
    
    context(@"type conversion", ^{
        
        __block MRBContext *mrbContext;
        beforeEach(^{
            mrbContext = [[MRBContext alloc] init];
        });
        
        afterEach(^{
            mrbContext = nil;
        });
                
        it(@"ruby nil -> OC nil", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"nil"];
            [[theValue(mrbRet.isNil) should] beYes];
        });
        
        it(@"ruby nil -> OC nil", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"nil"];
            [[mrbRet.toNil should] beNil];
        });
        
        it(@"ruby NSNull -> OC NSNull", ^{
            MRBValue *mrbRet = [mrbContext evaluateScript:@"require_cocoa 'NSNull';NSNull.null"];
            [[[mrbRet.toObject class] should] equal:NSNull.class];
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
        
        afterEach(^{
            mrbContext = nil;
        });
        
        it(@"shold has a return value that equal param",^{
            [mrbContext evaluateScript:@"def a_method(val); val; end;"];
            MRBValue *mrbVal = [MRBValue valueWithInt64:100 inContext:mrbContext];
            MRBValue *mrbRet = [mrbContext callFunc:@"a_method" args:@[mrbVal]];
            [[theValue(mrbRet.toInt64) should] equal:theValue(100)];
        });
    });
    
    context(@"OC register method or Const value to ruby", ^{
        __block MRBContext *mrbContext;
    
        beforeEach(^{
            mrbContext = [[MRBContext alloc] init];
        });
        
        afterEach(^{
            mrbContext = nil;
        });
        
        it(@"register method", ^{
            [mrbContext registerFunc:@"sum" block:^NSNumber * (NSNumber *a, NSNumber *b) {
                double sum = a.doubleValue + b.doubleValue;
                return @(sum);
            }];
            MRBValue *retVal = [mrbContext evaluateScript:@"MRBCocoa.sum(1,2)"];
            [[retVal.toNumber should] equal:@3];
        });
        
        it(@"register Const Value", ^{
            NSURL *url = [NSURL URLWithString:@"scheme://host/path"];
            [mrbContext registerConst:@"URL" value:url];
            MRBValue *retVal = [mrbContext evaluateScript:@"MRBCocoa::Const::URL"];
            [[retVal.toObject should] equal:url];
        });
    });
    
    context(@"ruby call c func", ^{
        __block MRBContext *mrbContext;
    
        beforeEach(^{
            mrbContext = [[MRBContext alloc] init];
        });
        
        afterEach(^{
            mrbContext = nil;
        });
        
        it(@"call c func", ^{
            MRBValue *retVal = [mrbContext evaluateScript:@"MRBCocoa.define_cfunc('sumx','int,int,int');MRBCocoa.cfunc_call('sumx',1,2)"];
            [[theValue(retVal.toInt64) should] equal:theValue(3)];
        });
    });
    
    context(@"ruby call oc method", ^{
        
        __block MRBContext *mrbContext;
        
        beforeEach(^{
            mrbContext = [[MRBContext alloc] init];
            [mrbContext evaluateScript:@"require_cocoa 'Person'; person = Person.alloc.init; person.setName_('anan');person.setAge_(2)"];
        });
        
        afterEach(^{
            mrbContext = nil;
        });
        
                
        it(@"call commod method", ^{
            MRBValue *retVal = [mrbContext evaluateScript:@"person.saySth_('love ruby')"];
            [[[retVal toString] should] equal:@"love ruby"];
        });
        
        it(@"call method that the middle of method's name has '_'", ^{
            MRBValue *retVal = [mrbContext evaluateScript:@"person.say__sth_('love ruby')"];
            [[[retVal toString] should] equal:@"love ruby"];
        });
        
        it(@"call method that the beginning of method's name has '_'", ^{
            MRBValue *retVal = [mrbContext evaluateScript:@"person.__say__something_('love ruby')"];
            [[[retVal toString] should] equal:@"love ruby"];
        });
        
        it(@"call method that has block params", ^{
            MRBValue *retVal = [mrbContext evaluateScript:@"finished = Proc.new {|name, age| \"I am #{name}, #{age} years old\" };finished_block = finished.to_cocoa_block(\"NSString *, NSString *, int\");person.finished_(finished_block)"];
            [[[retVal toString] should] equal:@"hi,I am anan, 2 years old"];
            
        });
    });
});

SPEC_END


