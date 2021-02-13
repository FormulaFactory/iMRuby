//
//  MRBInvocation.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBInvocation.h"

@implementation MRBInvocation

- (instancetype)initWithTarget:(id)target sign:(NSMethodSignature *)sign
{
    if (self = [super init]) {
        _target = target;
        _sign = sign;
    }
    
    return self;
}

- (void)setArguments:(NSArray *)arguments
{
    _arguments = arguments;
}

- (id)invokeAndReturn
{
    // sub class
    return nil;
}

#pragma mark -

- (void)setArgument:(id)arg
            argType:(const char *)argType
              index:(NSInteger)index
                inv:(NSInvocation *)inv
{
    switch (argType[0]) {
#define MRB_INK_ARG_NUM_CASE(_encode, _type, _selector) { \
    case _encode: { \
            _type value = [(NSNumber *)arg _selector]; \
            [inv setArgument:(void *)&value atIndex:index]; \
            break; \
        } \
    }
        
            MRB_INK_ARG_NUM_CASE('c', char, charValue);
            MRB_INK_ARG_NUM_CASE('C', unsigned char, unsignedCharValue);
            MRB_INK_ARG_NUM_CASE('s', short, shortValue);
            MRB_INK_ARG_NUM_CASE('S', unsigned short, unsignedShortValue);
            MRB_INK_ARG_NUM_CASE('i', int, intValue);
            MRB_INK_ARG_NUM_CASE('I', unsigned int, unsignedIntValue);
            MRB_INK_ARG_NUM_CASE('l', long, longValue);
            MRB_INK_ARG_NUM_CASE('L', unsigned long, unsignedLongValue);
            MRB_INK_ARG_NUM_CASE('q', long long, longLongValue);
            MRB_INK_ARG_NUM_CASE('Q', unsigned long long, unsignedLongLongValue);
            MRB_INK_ARG_NUM_CASE('f', float, floatValue);
            MRB_INK_ARG_NUM_CASE('d', double, doubleValue);
            MRB_INK_ARG_NUM_CASE('B', BOOL, boolValue);
        case '{': {
#define MRB_INK_ARG_STRUCT(_encode, _type, _selector) {\
    if (strcmp(argType, _encode)==0) { \
        _type value = [(NSValue *)arg _selector]; \
        [inv setArgument:&value atIndex:index]; \
    } \
}
            MRB_INK_ARG_STRUCT("{CGSize=dd}", CGSize, CGSizeValue);
            MRB_INK_ARG_STRUCT("{CGPoint=dd}", CGPoint, CGPointValue);
            MRB_INK_ARG_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, CGRectValue);
            MRB_INK_ARG_STRUCT("{_NSRange=QQ}", NSRange, rangeValue);
            break;
        }
        case '#':
        case '@': {
            [inv setArgument:&arg atIndex:index];
            break;
        }
            
        default:
            NSAssert(NO, @"not surport type: %@", [NSString stringWithCString:argType encoding:NSUTF8StringEncoding]);
            break;
    }
}

- (id)getReturnValue:(const char *)returnType inv:(NSInvocation *)inv
{
    id ret;
    switch (returnType[0]) {
#define MRB_INK_RET_NUM_CASE(_encode, _type, _selector) { \
    case _encode: { \
            _type returnValue; \
            [inv getReturnValue:&returnValue]; \
            ret = [[NSNumber alloc] _selector:returnValue]; \
            break; \
        } \
    } \
    
            MRB_INK_RET_NUM_CASE('c', char, initWithChar);
            MRB_INK_RET_NUM_CASE('C', unsigned char, initWithUnsignedChar);
            MRB_INK_RET_NUM_CASE('s', short, initWithShort);
            MRB_INK_RET_NUM_CASE('S', unsigned short, initWithUnsignedShort);
            MRB_INK_RET_NUM_CASE('i', int, initWithInt);
            MRB_INK_RET_NUM_CASE('I', unsigned int, initWithUnsignedInt);
            MRB_INK_RET_NUM_CASE('l', long, initWithLong);
            MRB_INK_RET_NUM_CASE('L', unsigned long, initWithUnsignedLong);
            MRB_INK_RET_NUM_CASE('q', long long, initWithLongLong);
            MRB_INK_RET_NUM_CASE('Q', unsigned long long, initWithUnsignedLongLong);
            MRB_INK_RET_NUM_CASE('f', float, initWithFloat);
            MRB_INK_RET_NUM_CASE('d', double, initWithDouble);
            MRB_INK_RET_NUM_CASE('B', BOOL, initWithBool);

        case '{': {
#define MRB_INK_RET_STRUCT(_encode, _type, _selector) { \
            if (strcmp(returnType, _encode)==0) { \
                _type returnValue; \
                [inv getReturnValue:&returnValue]; \
                ret = [NSValue _selector:returnValue]; \
            } \
        }
            MRB_INK_RET_STRUCT("{CGSize=dd}", CGSize, valueWithCGSize)
            MRB_INK_RET_STRUCT("{CGPoint=dd}", CGPoint, valueWithCGPoint)
            MRB_INK_RET_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, valueWithCGRect)
            MRB_INK_RET_STRUCT("{_NSRange=QQ}", NSRange, valueWithRange)
            break;
        }
        case '#':
        case '@':
        {
            void *returnValue;
            [inv getReturnValue:&returnValue];
            ret = (__bridge id)returnValue;
        }
            break;
        case 'v':
        {
            ret = nil;
        }
            break;
            
        default:
            NSAssert(NO, @"not surport type: %@", [NSString stringWithCString:returnType encoding:NSUTF8StringEncoding]);
            ret = nil;
            break;
    }

    return ret;
}
@end

