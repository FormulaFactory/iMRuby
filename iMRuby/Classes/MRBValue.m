//
//  MRBValue.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBValue.h"
#import "MRBContext.h"
#import "MRBBlockValue.h"
#import "MRBObjectValue.h"
#import "MRBKlassValue.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface MRBValue()

@property (strong) MRBContext *context;
@property (nonatomic, assign) mrb_value mrb_value;

@end

@implementation MRBValue {
    mrb_value mrbValue;
}

- (instancetype)init
{
    if (self) {
        self = [super init];
    }
    
    return self;
}

#pragma mark - CoCoa --> MRBValue(mrb)

+ (MRBValue *)valueWithMrbValue:(mrb_value)mrb_value inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_value;
    value.context = context;
    
    return value;
};

+ (MRBValue *)valueNilInContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_nil_value();
    value.context = context;
    return value;
}

+ (MRBValue *)valueWithString:(NSString *)string inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_str_new_cstr(context.current_mrb, [string UTF8String]);
    value.context = context;
    return value;
}

+ (MRBValue *)valueWithInt64:(int64_t)i inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_fixnum_value(i);
    value.context = context;
    return value;
}

+ (MRBValue *)valueWithUInt64:(uint64_t)i inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_fixnum_value(i);
    value.context = context;
    return value;
}

+ (MRBValue *)valueWithDouble:(double)d inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = mrb_float_value(context.current_mrb, d);
    value.context = context;
    return value;
}

+ (MRBValue *)valueWithBoolean:(BOOL)b inContext:(MRBContext *)context
{
    MRBValue *value = [[self alloc] init];
    value.mrb_value = b ? mrb_true_value() : mrb_false_value();
    value.context = context;
    return value;
}

+ (MRBValue *)valuewithDate:(NSDate *)date inContext:(MRBContext *)context
{
    NSTimeInterval time = date.timeIntervalSince1970;
    mrb_value mrb_time_class_obj = mrb_obj_value(mrb_class_get(context.current_mrb, "Time"));
    mrb_value mrb_time_obj = mrb_funcall(context.current_mrb, mrb_time_class_obj, "at", 1,mrb_fixnum_value(time));
    MRBValue *value = [self valueWithMrbValue:mrb_time_obj inContext:context];
    if (value.isNil) {
        return nil;
    }
    return value;
}

+ (MRBValue *)valueWithBlock:(id)block inContext:(MRBContext *)context
{
    mrb_value mrb_block = [MRBBlockValue generateMRBBlock:block context:context];
    MRBValue *value = [self valueWithMrbValue:mrb_block inContext:context];
    if (value.isNil) {return nil;}
    return value;
}

+ (MRBValue *)valueWithObject:(id)object inContext:(MRBContext *)context
{
    mrb_value mrb_object = [MRBObjectValue generateMRBObject:object context:context];
    MRBValue *value = [self valueWithMrbValue:mrb_object inContext:context];
    if (value.isNil) {
        return nil;
    }
    return value;
}

+ (MRBValue *)valueWithKlass:(Class)klass inContext:(MRBContext *)context
{
    mrb_value mrb_klass = [MRBKlassValue generateMRBKlass:klass context:context];
    MRBValue *value = [self valueWithMrbValue:mrb_klass inContext:context];
    if (value.isNil) {
        return nil;
    }
    return value;
}

+ (MRBValue *)valueWithArray:(NSArray *)array inContext:(MRBContext *)context
{
    mrb_value mrb_ary_value = mrb_ary_new(context.current_mrb);
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        MRBValue *convertValue = [MRBValue convertToMRBValueWithObj:obj inContext:context];
        if (!convertValue) {
            convertValue = [MRBValue valueNilInContext:context];
        }
        mrb_ary_push(context.current_mrb, mrb_ary_value, convertValue.mrb_value);
    }];
    MRBValue *value = [MRBValue valueWithMrbValue:mrb_ary_value inContext:context];
    return value;
}

+ (MRBValue *)valuewithDictionary:(NSDictionary *)dict inContext:(MRBContext *)context
{
    __block BOOL dictValid = YES;
    mrb_value mrb_hash_value = mrb_hash_new(context.current_mrb);
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![key isKindOfClass:[NSString class]]) {
            // TODO: throw exception
            dictValid = NO;
        }
        mrb_value hash_key = mrb_str_new_cstr(context.current_mrb, [(NSString *)key UTF8String]);
        MRBValue *convertValue = [MRBValue convertToMRBValueWithObj:obj inContext:context];
        if (!convertValue) {
            convertValue = [MRBValue valueNilInContext:context];
        }
        mrb_hash_set(context.current_mrb, mrb_hash_value, hash_key, convertValue.mrb_value);
    }];
    
    if (!dictValid) {
        return nil;
    }
    
    MRBValue *value = [MRBValue valueWithMrbValue:mrb_hash_value inContext:context];
    return value                                                            ;
}

+ (MRBValue *)valueWithPoint:(CGPoint)point inContext:(MRBContext *)context
{
    mrb_state *mrb = context.current_mrb;
    mrb_value point_hash = mrb_hash_new_capa(mrb, 2);
    mrb_hash_set(mrb, point_hash, mrb_str_new_cstr(mrb, "x"), mrb_float_value(mrb, point.x));
    mrb_hash_set(mrb, point_hash, mrb_str_new_cstr(mrb, "y"), mrb_float_value(mrb, point.y));
    MRBValue *value = [MRBValue valueWithMrbValue:point_hash inContext:context];
    return value;
}

+ (MRBValue *)valueWithSize:(CGSize)size inContext:(MRBContext *)context
{
    mrb_state *mrb = context.current_mrb;
    mrb_value size_hash = mrb_hash_new_capa(mrb, 2);
    mrb_hash_set(mrb, size_hash, mrb_str_new_cstr(mrb, "width"), mrb_float_value(mrb, size.width));
    mrb_hash_set(mrb, size_hash, mrb_str_new_cstr(mrb, "height"), mrb_float_value(mrb, size.height));
    MRBValue *value = [MRBValue valueWithMrbValue:size_hash inContext:context];
    return value;
}

+ (MRBValue *)valueWithRect:(CGRect)rect inContext:(MRBContext *)context
{
    mrb_state *mrb = context.current_mrb;
    mrb_value rect_hash = mrb_hash_new_capa(mrb, 4);
    mrb_hash_set(mrb, rect_hash, mrb_str_new_cstr(mrb, "x"), mrb_float_value(mrb, rect.origin.x));
    mrb_hash_set(mrb, rect_hash, mrb_str_new_cstr(mrb, "y"), mrb_float_value(mrb, rect.origin.y));
    mrb_hash_set(mrb, rect_hash, mrb_str_new_cstr(mrb, "width"), mrb_float_value(mrb, rect.size.width));
    mrb_hash_set(mrb, rect_hash, mrb_str_new_cstr(mrb, "height"), mrb_float_value(mrb, rect.size.height));
    MRBValue *value  = [MRBValue valueWithMrbValue:rect_hash inContext:context];
    return value;
}

+ (MRBValue *)valueWithRange:(NSRange)range inContext:(MRBContext *)context
{
    mrb_state *mrb = context.current_mrb;
    mrb_value range_hash = mrb_hash_new_capa(mrb, 2);
    mrb_hash_set(mrb, range_hash, mrb_str_new_cstr(mrb, "location"), mrb_fixnum_value( range.location));
    mrb_hash_set(mrb, range_hash, mrb_str_new_cstr(mrb, "length"), mrb_fixnum_value(range.length));
    MRBValue *value = [MRBValue valueWithMrbValue:range_hash inContext:context];
    return value;
}


#pragma mark - helper methods

+ (nullable MRBValue *)convertToMRBValueWithObj:(id)obj inContext:(MRBContext *)context
{
    if ([obj isKindOfClass:[NSValue class]]) {
         const char* type = [(NSValue *)obj objCType];
        
        if (strcmp(type, "{CGSize=dd}")==0) {
            CGSize size = [(NSValue *)obj CGSizeValue];
            return [MRBValue valueWithSize:size inContext:context];
        }
        
        if (strcmp(type, "{CGPoint=dd}")==0) {
            CGPoint point = [(NSValue *)obj CGPointValue];
            return [MRBValue valueWithPoint:point inContext:context];
        }
        
        if (strcmp(type, "{_NSRange=QQ}")==0) {
            NSRange range = [(NSValue *)obj rangeValue];
            return [MRBValue valueWithRange:range inContext:context];
        }
        
        if (strcmp(type, "{CGRect={CGPoint=dd}{CGSize=dd}}") == 0) {
            CGRect rect = [(NSValue *)obj CGRectValue];
            return [MRBValue valueWithRect:rect inContext:context];
        }
    }
    
    if (object_isClass(obj)) {
        return [MRBValue valueWithKlass:obj inContext:context];
    }
    
    if ([obj isKindOfClass:[NSString class]]) {
        return [MRBValue valueWithString:obj inContext:context];
    }
    
    if ([obj isKindOfClass:[NSNumber class]]) {
        NSNumber *num = (NSNumber *)obj;
        const char* type = [num objCType];
        
        if (strcmp(type, "B")==0) {
            // 理论上不会进入该条件
            return [MRBValue valueWithBoolean:num.boolValue inContext:context];
        }
        
        if (strcmp(type, "c")==0 || strcmp(type, "C")==0) {
            char c = ((NSNumber *)obj).charValue;
            if (strcmp(&c, "\0") == 0 || strcmp(&c, "\x01")) {
                return [MRBValue valueWithBoolean:num.boolValue inContext:context];
            }
        }
        
        if (strcmp(type, "i") == 0 ||
            strcmp(type, "s") == 0 ||
            strcmp(type, "l") == 0 ||
            strcmp(type, "q") == 0) {
            return [MRBValue valueWithInt64:num.longLongValue inContext:context];
        }
        
        if (strcmp(type, "I") == 0 ||
            strcmp(type, "S") == 0 ||
            strcmp(type, "L") == 0 ||
            strcmp(type, "Q") == 0) {
            return [MRBValue valueWithUInt64:num.unsignedLongLongValue inContext:context];
        }
        
        if (strcmp(type, "f") == 0 ||
            strcmp(type, "d") == 0) {
            return [MRBValue valueWithDouble:num.doubleValue inContext:context];
        }
    }
    
    if ([obj isKindOfClass:[NSDate class]]) {
        return [MRBValue valuewithDate:obj inContext:context];
    }
    
    if ([obj isKindOfClass:[NSNull class]]) {
        return [MRBValue valueNilInContext:context];
    }
    
    if ([obj isKindOfClass:[NSArray class]]) {
        return [MRBValue valueWithArray:obj inContext:context];
    }
    
    if ([obj isKindOfClass:[NSDictionary class]]) {
        return [MRBValue valuewithDictionary:obj inContext:context];
    }
    
    NSString *object_class_name = NSStringFromClass([obj class]);
    if ([object_class_name isEqualToString:@"__NSGlobalBlock__"] ||
        [object_class_name isEqualToString:@"__NSMallocBlock__"] ||
        [object_class_name isEqualToString:@"__NSStackBlock__"]) {
        
        return [MRBValue valueWithBlock:obj inContext:context];
    }
    
    if ([obj isKindOfClass:[NSObject class]]) {
        return [MRBValue valueWithObject:obj inContext:context];
    }
    
    return nil;
}

#pragma mark - MRBContext(mrb) -> cocoa

- (nullable NSString *)toString
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_STRING && type != MRB_TT_SYMBOL) {
        return nil;
    }
    
    mrb_value result = mrbValue;
    if (type == MRB_TT_SYMBOL) {
        result = mrb_funcall(self.context.current_mrb, mrbValue, "to_s", 0);
    }
    
    if (mrb_type(result) == MRB_TT_STRING) {
        const char *cstr = mrb_string_cstr(self.context.current_mrb, result);
        return [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
    } else {
        return nil;
    }
}

- (nullable NSNumber *)toNumber
{
    // Fixnum Float boolean
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type == MRB_TT_FALSE) {
        return @0;
    } else if (type == MRB_TT_TRUE) {
        return @1;
    } else if (type == MRB_TT_FIXNUM) {
        mrb_int i = mrb_fixnum(mrbValue);
        return @(i);
    } else if (type == MRB_TT_FLOAT) {
        mrb_float f = mrb_float(mrbValue);
        return @(f);
    } else {
        return nil;
    }
}

- (BOOL)toBool
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type == MRB_TT_TRUE) {
        return YES;
    } else if (type == MRB_TT_FALSE) {
        return NO;
    } else {
        return NSNotFound;
    }
}

- (int64_t)toInt64
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_FIXNUM) {
        return NSNotFound;
    }
    return mrb_fixnum(mrbValue);
}

- (uint64_t)toUInt64
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_FIXNUM) {
        return NSNotFound;
    }
    return mrb_fixnum(mrbValue);
}

- (double)toDouble
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_FLOAT) {
        return NSNotFound;
    }
    
    return mrb_float(mrbValue);
}

- (nullable NSDate *)toDate
{
    mrb_value mrb_time = self.mrb_value;
    enum mrb_vtype type = mrb_type(mrb_time);
    if (type != MRB_TT_DATA) {
        return nil;
    }
    const mrb_data_type *data_type = DATA_TYPE(mrb_time);
    if (strcmp(data_type->struct_name, "Time") == 0) {
        mrb_value time_i =  mrb_funcall(self.context.current_mrb, mrb_time, "to_i", 0);
        enum mrb_vtype time_i_type = mrb_type(time_i);
        if (time_i_type != MRB_TT_FIXNUM) {
            return nil;
        }
        mrb_int i = mrb_fixnum(time_i);
        return [NSDate dateWithTimeIntervalSince1970:i];
    }
    return nil;
}

- (nullable id)toBlock
{
    mrb_value mrb_block = self.mrb_value;
    return [MRBBlockValue getBlock:mrb_block context:self.context];
}

- (nullable id)toObject;
{
    mrb_value mrb_object = self.mrb_value;
    return [MRBObjectValue getObject:mrb_object context:self.context];
}

- (nullable Class)toKlass
{
    mrb_value mrb_klass = self.mrb_value;
    return [MRBKlassValue getKlass:mrb_klass context:self.context];
}

- (nullable NSArray *)toArray
{
    mrb_value mrb_ary = self.mrb_value;
    enum mrb_vtype type = mrb_type(mrb_ary);
    if (type != MRB_TT_ARRAY) {
        return nil;
    }
    mrb_int length = RARRAY_LEN(mrb_ary);
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:length];
    for (int i=0; i<length; i++) {
        mrb_value mrbValue = mrb_ary_ref(self.context.current_mrb, mrb_ary, i);
        id obj = [MRBValue convertToObjectWithMrbValue:mrbValue inContext:self.context];
        [array addObject:obj];
    }
    
    return array;
}

- (nullable NSDictionary *)toDict
{
    mrb_value mrb_hash = self.mrb_value;
    if (!mrb_hash_p(mrb_hash)) {
        return nil;
    }
    mrb_value hash_keys = mrb_hash_keys(self.context.current_mrb, mrb_hash);
    MRBValue *keysMRBValue = [MRBValue valueWithMrbValue:hash_keys inContext:self.context];
    NSArray<NSString *> *keys = [keysMRBValue toArray];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:keys.count];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        mrb_value mrb_key = mrb_str_new_cstr(self.context.current_mrb, [key UTF8String]);
        mrb_value mrb_obj = mrb_hash_get(self.context.current_mrb, mrb_hash, mrb_key);
        id obj = [MRBValue convertToObjectWithMrbValue:mrb_obj inContext:self.context];
        [dict setObject:obj forKey:key];
    }];
    return dict;
}

- (CGPoint)toPoint
{
    if (!self.isDict) {
        // TODO: throw exception
        return CGPointZero;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return CGPointZero;
    }
    mrb_value x = mrb_str_new_cstr(mrb, "x");
    mrb_value y = mrb_str_new_cstr(mrb, "y");
    mrb_value pointx = mrb_hash_get(mrb, mrbValue, x);
    mrb_value pointy = mrb_hash_get(mrb, mrbValue, y);
    if ((mrb_float_p(pointx) || mrb_fixnum_p(pointx)) && (mrb_float_p(pointy) || mrb_fixnum_p(pointy))) {
        CGFloat X = 0;
        CGFloat Y = 0;
        if (mrb_float_p(pointx)) {
            X = mrb_float(pointx);
        } else if (mrb_fixnum_p(pointx)) {
            X = mrb_fixnum(pointx);
        }
        
        if (mrb_float_p(pointy)) {
            Y = mrb_float(pointy);
        } else if (mrb_fixnum_p(pointy)) {
            Y = mrb_fixnum(pointy);
        }
        
        return CGPointMake(X, Y);
    }
    
    return CGPointZero;
}

- (CGSize)toSize
{
    if (!self.isDict) {
        return CGSizeZero;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return CGSizeZero;
    }
    mrb_value width = mrb_str_new_cstr(mrb, "width");
    mrb_value height = mrb_str_new_cstr(mrb, "height");
    mrb_value sizeWidth = mrb_hash_get(mrb, mrbValue, width);
    mrb_value sizeHeight = mrb_hash_get(mrb, mrbValue, height);
    if ((mrb_float_p(sizeWidth) || mrb_fixnum_p(sizeWidth)) && (mrb_float_p(sizeHeight) || mrb_fixnum_p(sizeHeight))) {
        CGFloat WIDTH = 0;
        CGFloat HEIGHT = 0;
        if (mrb_float_p(sizeWidth)) {
            WIDTH = mrb_float(sizeWidth);
        } else if (mrb_fixnum_p(sizeWidth)) {
            WIDTH = mrb_fixnum(sizeWidth);
        }
        
        if (mrb_float_p(sizeHeight)) {
            HEIGHT = mrb_float(sizeHeight);
        } else if (mrb_fixnum_p(sizeHeight)) {
            HEIGHT = mrb_fixnum(sizeHeight);
        }
        
        return CGSizeMake(WIDTH, HEIGHT);
    }
    return CGSizeZero;
}
- (CGRect)toRect
{
    if (!self.isDict) {
        return CGRectZero;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 4) {
        return CGRectZero;
    }
    mrb_value x = mrb_str_new_cstr(mrb, "x");
    mrb_value y = mrb_str_new_cstr(mrb, "y");
    mrb_value pointx = mrb_hash_get(mrb, mrbValue, x);
    mrb_value pointy = mrb_hash_get(mrb, mrbValue, y);
    mrb_value width = mrb_str_new_cstr(mrb, "width");
    mrb_value height = mrb_str_new_cstr(mrb, "height");
    mrb_value sizeWidth = mrb_hash_get(mrb, mrbValue, width);
    mrb_value sizeHeight = mrb_hash_get(mrb, mrbValue, height);

    if ( ((mrb_float_p(sizeWidth) || mrb_fixnum_p(sizeWidth)) && (mrb_float_p(sizeHeight) || mrb_fixnum_p(sizeHeight))) && ((mrb_float_p(pointx) || mrb_fixnum_p(pointx)) && (mrb_float_p(pointy) || mrb_fixnum_p(pointy)))) {
        CGFloat X = 0;
        CGFloat Y = 0;
        CGFloat WIDTH = 0;
        CGFloat HEIGHT = 0;
        if (mrb_float_p(pointx)) {
            X = mrb_float(pointx);
        } else if (mrb_fixnum_p(pointx)) {
            X = mrb_fixnum(pointx);
        }
        
        if (mrb_float_p(pointy)) {
            Y = mrb_float(pointy);
        } else if (mrb_fixnum_p(pointy)) {
            Y = mrb_fixnum(pointy);
        }
        
        if (mrb_float_p(sizeWidth)) {
            WIDTH = mrb_float(sizeWidth);
        } else if (mrb_fixnum_p(sizeWidth)) {
            WIDTH = mrb_fixnum(sizeWidth);
        }
        
        if (mrb_float_p(sizeHeight)) {
            HEIGHT = mrb_float(sizeHeight);
        } else if (mrb_fixnum_p(sizeHeight)) {
            HEIGHT = mrb_fixnum(sizeHeight);
        }

        return CGRectMake(X, Y, WIDTH, HEIGHT);
    }

    return CGRectZero;
}
- (NSRange)toRange
{
    if (!self.isDict) {
        return NSMakeRange(0, 0);
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return NSMakeRange(0, 0);
    }
    
    mrb_value location = mrb_str_new_cstr(mrb, "location");
    mrb_value length = mrb_str_new_cstr(mrb, "length");
    mrb_value rangeLocation = mrb_hash_get(mrb, mrbValue, location);
    mrb_value rangeLength = mrb_hash_get(mrb, mrbValue, length);
    if (mrb_fixnum_p(rangeLocation) && mrb_fixnum_p(rangeLength)) {
        NSUInteger LOCATION = mrb_fixnum(rangeLocation);
        NSInteger LENGTH = mrb_fixnum(rangeLength);
        return NSMakeRange(LOCATION, LENGTH);
    }
    
    return NSMakeRange(0, 0);
}

+ (id)convertToObjectWithMrbValue:(mrb_value)mrbValue inContext:(MRBContext *)context
{
    MRBValue *value = [MRBValue valueWithMrbValue:mrbValue inContext:context];
    if (value.isRect) {
        return [NSValue valueWithCGRect:value.toRect];
    }
    
    if (value.isSize) {
        return [NSValue valueWithCGSize:value.toSize];
    }
    
    if (value.isPoint) {
        return [NSValue valueWithCGPoint:value.toPoint];
    }
    
    if (value.isRange) {
        return [NSValue valueWithRange:value.toRange];
    }
        
    if (value.isNil) {
        return [NSNull null];
    }
    
    if (value.isString) {
        return value.toString;
    }
    
    if (value.isNumber) {
        return value.toNumber;
    }
    
    if (value.isDate) {
        return value.toDate;
    }
    
    if (value.isBlock) {
        return value.toBlock;
    }
    
    if (value.isObject) {
        return value.toObject;
    }
    
    if (value.isKlass) {
        return value.toKlass;
    }
    
    if (value.isArray) {
        return value.toArray;
    }
    
    if (value.isDict) {
        return value.toDict;
    }
    
    return [NSNull null];
}


#pragma mark - type

- (BOOL)isNil
{
    return mrb_type(mrbValue) == MRB_TT_FALSE && mrb_fixnum(mrbValue) == 0;
}

- (BOOL)isString
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_STRING || type == MRB_TT_SYMBOL;
}

- (BOOL)isNumber
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_TRUE || type == MRB_TT_FALSE || type == MRB_TT_FIXNUM || type == MRB_TT_FLOAT;
}

- (BOOL)isDouble
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_FLOAT;
}

- (BOOL)isInt64
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_FIXNUM;
}

- (BOOL)isUInt64
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_FIXNUM && mrb_fixnum(mrbValue)>=0;
}

- (BOOL)isBool
{
    enum mrb_vtype type = mrb_type(mrbValue);
    return type == MRB_TT_TRUE || type == MRB_TT_FALSE;
}

- (BOOL)isDate
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_DATA) {
        return NO;
    }
    
    const mrb_data_type *data_type = DATA_TYPE(mrbValue);
    return strcmp(data_type->struct_name, "Time")==0;
}

- (BOOL)isBlock
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_DATA) {
        return NO;
    }
    const mrb_data_type *date_type = DATA_TYPE(mrbValue);
    return strcmp(date_type->struct_name, "CocoaBlock")==0;
}

- (BOOL)isObject
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_DATA) {
        return NO;
    }
    const mrb_data_type *object_type = DATA_TYPE(mrbValue);
    return strcmp(object_type->struct_name, "CocoaObject")==0;
}

- (BOOL)isKlass
{
    enum mrb_vtype type = mrb_type(mrbValue);
    if (type != MRB_TT_DATA) {
        return NO;
    }
    const mrb_data_type *klass_type = DATA_TYPE(mrbValue);
    return strcmp(klass_type->struct_name, "CocoaKlass")==0;
}

- (BOOL)isArray
{
    return mrb_array_p(mrbValue);
}

- (BOOL)isDict
{
    return mrb_hash_p(mrbValue);
}

- (BOOL)isPoint
{
    if (!self.isDict) {
        return NO;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return NO;
    }
    mrb_value x = mrb_str_new_cstr(mrb, "x");
    mrb_value y = mrb_str_new_cstr(mrb, "y");
    mrb_value pointx = mrb_hash_get(mrb, mrbValue, x);
    mrb_value pointy = mrb_hash_get(mrb, mrbValue, y);
    return (mrb_float_p(pointx) || mrb_fixnum_p(pointx)) && (mrb_float_p(pointy) || mrb_fixnum_p(pointy));
}

- (BOOL)isSize
{
    if (!self.isDict) {
        return NO;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return NO;
    }
    mrb_value width = mrb_str_new_cstr(mrb, "width");
    mrb_value height = mrb_str_new_cstr(mrb, "height");
    mrb_value sizeWidth = mrb_hash_get(mrb, mrbValue, width);
    mrb_value sizeHeight = mrb_hash_get(mrb, mrbValue, height);
    return (mrb_float_p(sizeWidth) || mrb_fixnum_p(sizeWidth)) && (mrb_float_p(sizeHeight) || mrb_fixnum_p(sizeHeight));
}

- (BOOL)isRect
{
    if (!self.isDict) {
        return NO;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 4) {
        return NO;
    }
    mrb_value x = mrb_str_new_cstr(mrb, "x");
    mrb_value y = mrb_str_new_cstr(mrb, "y");
    mrb_value pointx = mrb_hash_get(mrb, mrbValue, x);
    mrb_value pointy = mrb_hash_get(mrb, mrbValue, y);
    mrb_value width = mrb_str_new_cstr(mrb, "width");
    mrb_value height = mrb_str_new_cstr(mrb, "height");
    mrb_value sizeWidth = mrb_hash_get(mrb, mrbValue, width);
    mrb_value sizeHeight = mrb_hash_get(mrb, mrbValue, height);

    return ((mrb_float_p(sizeWidth) || mrb_fixnum_p(sizeWidth)) && (mrb_float_p(sizeHeight) || mrb_fixnum_p(sizeHeight))) && ((mrb_float_p(pointx) || mrb_fixnum_p(pointx)) && (mrb_float_p(pointy) || mrb_fixnum_p(pointy)));
}

- (BOOL)isRange
{
    if (!self.isDict) {
        return NO;
    }
    mrb_state *mrb = self.context.current_mrb;
    if (mrb_hash_size(mrb, mrbValue) != 2) {
        return NO;
    }
    
    mrb_value location = mrb_str_new_cstr(mrb, "location");
    mrb_value length = mrb_str_new_cstr(mrb, "length");
    mrb_value rangeLocation = mrb_hash_get(mrb, mrbValue, location);
    mrb_value rangeLength = mrb_hash_get(mrb, mrbValue, length);
    return mrb_fixnum_p(rangeLocation) && mrb_fixnum_p(rangeLength);
}

#pragma mark - setter & getter
- (void)setMrb_value:(mrb_value)mrb_value
{
    mrbValue = mrb_value;
}

- (mrb_value)mrb_value
{
    return mrbValue;
}

@end
