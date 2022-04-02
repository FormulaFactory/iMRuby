//
//  MRBValue.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>
@import MRuby;

@class MRBContext;

NS_ASSUME_NONNULL_BEGIN

@interface MRBValue : NSObject

@property (readonly, strong) MRBContext *context;

//**
//Objective-C type  |   ruby type
//--------------------+---------------------
//      nil         |        nil
//    NSString      |   string, symbol
//    NSNumber      |   Fixnum, Float, boolean
//  NSDictionary    |   Hash
//    NSArray       |   Array
//     NSDate       |   Time
//   NSBlock        |   Wrapper object  ruby class MRBCocoa::Block
//       id         |   Wrapper object  ruby class MRBCocoa::Object
//     Class        |   Wrapper object  ruby class MRBCocoa::Klass
//     CGPoint      |   specific Hash {'x' => 1, 'y' => 1}
//     CGSize       |   specific Hash {'width' => 1, 'height' => 1}
//     CGReect      |   specific Hash {'x' => 1, 'y' => 1, 'width' => 1, 'height' => 1}
//     NSRange      |   specific Hash {'location' => 0, 'length' => 1}
//**

// cocoa value to MRBValue
+ (MRBValue *)valueNilInContext:(MRBContext *)context;
+ (MRBValue *)valueWithString:(NSString *)string inContext:(MRBContext *)context;
+ (MRBValue *)valueWithInt64:(int64_t)i inContext:(MRBContext *)context;
+ (MRBValue *)valueWithUInt64:(uint64_t)i inContext:(MRBContext *)context;
+ (MRBValue *)valueWithDouble:(double)d inContext:(MRBContext *)context;
+ (MRBValue *)valueWithBoolean:(BOOL)b inContext:(MRBContext *)context;
+ (MRBValue *)valuewithDate:(NSDate *)date inContext:(MRBContext *)context;
+ (MRBValue *)valueWithBlock:(id)block inContext:(MRBContext *)context;
+ (MRBValue *)valueWithObject:(id)object inContext:(MRBContext *)context;
+ (MRBValue *)valueWithKlass:(Class)klass inContext:(MRBContext *)context;
+ (MRBValue *)valueWithArray:(NSArray *)array inContext:(MRBContext *)context;
+ (MRBValue *)valuewithDictionary:(NSDictionary *)dict inContext:(MRBContext *)context;
+ (MRBValue *)valueWithPoint:(CGPoint)point inContext:(MRBContext *)context;
+ (MRBValue *)valueWithSize:(CGSize)size inContext:(MRBContext *)context;
+ (MRBValue *)valueWithRect:(CGRect)rect inContext:(MRBContext *)context;
+ (MRBValue *)valueWithRange:(NSRange)range inContext:(MRBContext *)context;

// MRBValue to cocoa value
- (nullable id)toNil;
- (nullable NSString *)toString;
- (nullable NSNumber *)toNumber;
- (BOOL)toBool;
- (int64_t)toInt64;
- (uint64_t)toUInt64;
- (double)toDouble;
- (nullable nullable NSDate *)toDate;
- (nullable nullable id)toBlock;
- (nullable id)toObject;
- (nullable Class)toKlass;
- (nullable nullable NSArray *)toArray;
- (nullable nullable NSDictionary *)toDict;
- (CGPoint)toPoint;
- (CGSize)toSize;
- (CGRect)toRect;
- (NSRange)toRange;

@property (readonly) BOOL isNil;
@property (readonly) BOOL isString;
@property (readonly) BOOL isNumber;
@property (readonly) BOOL isDouble;
@property (readonly) BOOL isInt64;
@property (readonly) BOOL isUInt64;
@property (readonly) BOOL isBool;
@property (readonly) BOOL isDate;
@property (readonly) BOOL isBlock;
@property (readonly) BOOL isObject;
@property (readonly) BOOL isKlass;
@property (readonly) BOOL isArray;
@property (readonly) BOOL isDict;
@property (readonly) BOOL isPoint;
@property (readonly) BOOL isSize;
@property (readonly) BOOL isRect;
@property (readonly) BOOL isRange;

// MRBValue get mrb_value
@property (readonly, nonatomic, assign) mrb_value mrb_value;

// mrb_value to MRBValue
+ (MRBValue *)valueWithMrbValue:(mrb_value)mrb_value inContext:(MRBContext *)context;

// convert helper method
+ (nullable MRBValue *)convertToMRBValueWithObj:(nullable id)obj inContext:(MRBContext *)context;
+ (nullable id)convertToObjectWithMrbValue:(mrb_value)mrbValue inContext:(MRBContext *)context;
@end

NS_ASSUME_NONNULL_END


