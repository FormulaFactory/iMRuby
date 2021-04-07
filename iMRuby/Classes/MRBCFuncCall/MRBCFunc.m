//
//  MRBCFunc.m
//  iMRuby
//
//  Created by ping.cao on 2021/3/19.
//

#import "MRBCFunc.h"
#import "MRBMethodSignature.h"
#import "ffi.h"
#import <dlfcn.h>
#import <UIKit/UIKit.h>

static NSString *trim(NSString *string)
{
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@implementation MRBCFunc

+ (NSString *)getEncodeStrWithTypes:(NSString *)types
{
    NSMutableString *encodeStr = [[NSMutableString alloc] init];
    NSArray *typeArr = [types componentsSeparatedByString:@","];
    for (NSInteger i = 0; i < typeArr.count; i++) {
        NSString *typeStr = trim([typeArr objectAtIndex:i]);
        NSString *encode = [MRBMethodSignature typeEncodeWithTypeName:typeStr];
        if (!encode) {
            if ([typeStr hasPrefix:@"{"] && [typeStr hasSuffix:@"}"]) {
                encode = typeStr;
            } else {
                
                NSString *argClassName = trim([typeStr stringByReplacingOccurrencesOfString:@"*" withString:@""]);
                if (NSClassFromString(argClassName) != NULL) {
                    encode = @"@";
                } else {
                    NSCAssert(NO, @"unreconized type %@", typeStr);
                    return nil;
                }
            }
        }
        [encodeStr appendString:encode];
    }
    return encodeStr;
}

+ (id)callCFunc:(NSString *)funcName args:(NSArray *)args encode:(NSString *)encode
{
    void *funcPtr = dlsym(RTLD_DEFAULT, [funcName UTF8String]);
    if (!funcPtr) {
        NSAssert(NO, @"iMRuby not find c func: %@", funcName);
        return nil;
    }
    
    MRBMethodSignature *funcSignature = [[MRBMethodSignature alloc] initWithObjCTypes:encode];
        
    NSUInteger argCount = funcSignature.argumentTypes.count;
    if (argCount != [args count]){
        return nil;
    }
    
    ffi_type **ffiArgTypes = alloca(sizeof(ffi_type *) *argCount);
    void **ffiArgs = alloca(sizeof(void *) *argCount);
    for (int i = 0; i < argCount; i ++) {
        const char *argumentType = [funcSignature.argumentTypes[i] UTF8String];
        ffi_type *ffiType = [MRBMethodSignature ffiTypeWithEncodingChar:argumentType];
        ffiArgTypes[i] = ffiType;
        void *ffiArgPtr = alloca(ffiType->size);
        [self convertObject:args[i] toCValue:ffiArgPtr forType:argumentType];
        ffiArgs[i] = ffiArgPtr;
    }
    
    ffi_cif cif;
    id ret = nil;
    const char *returnTypeChar = [funcSignature.returnType UTF8String];
    ffi_type *returnFfiType = [MRBMethodSignature ffiTypeWithEncodingChar:returnTypeChar];
    ffi_status ffiPrepStatus = ffi_prep_cif_var(&cif, FFI_DEFAULT_ABI, (unsigned int)0, (unsigned int)argCount, returnFfiType, ffiArgTypes);
    
    if (ffiPrepStatus == FFI_OK) {
        void *returnPtr = NULL;
        if (returnFfiType->size) {
            returnPtr = alloca(returnFfiType->size);
        }
        ffi_call(&cif, funcPtr, returnPtr, ffiArgs);

        if (returnFfiType->size) {
            ret = [self objectWithCValue:returnPtr forType:returnTypeChar];
        }
    }
    
    return ret;
}


+ (void)convertObject:(id)object toCValue:(void *)dist forType:(const char *)typeString
{
#define MRB_CALL_ARG_CASE(_typeString, _type, _selector)\
    case _typeString:{\
        *(_type *)dist = [(NSNumber *)object _selector];\
        break;\
    }
    switch (typeString[0]) {
        MRB_CALL_ARG_CASE('c', char, charValue)
        MRB_CALL_ARG_CASE('C', unsigned char, unsignedCharValue)
        MRB_CALL_ARG_CASE('s', short, shortValue)
        MRB_CALL_ARG_CASE('S', unsigned short, unsignedShortValue)
        MRB_CALL_ARG_CASE('i', int, intValue)
        MRB_CALL_ARG_CASE('I', unsigned int, unsignedIntValue)
        MRB_CALL_ARG_CASE('l', long, longValue)
        MRB_CALL_ARG_CASE('L', unsigned long, unsignedLongValue)
        MRB_CALL_ARG_CASE('q', long long, longLongValue)
        MRB_CALL_ARG_CASE('Q', unsigned long long, unsignedLongLongValue)
        MRB_CALL_ARG_CASE('f', float, floatValue)
        MRB_CALL_ARG_CASE('d', double, doubleValue)
        MRB_CALL_ARG_CASE('B', BOOL, boolValue)
        case '#':
        case '@': {
            id ptr = object;
            *(void **)dist = (__bridge void *)(ptr);
            break;
        }
        case '{': {
            
#define MRB_CALL_ARG_STRUCT(_encode, _type, _selector) { \
    if(strcmp(typeString, _encode)==0) {\
        _type value = [(NSValue *)object _selector];\
        *(_type *)dist = value; \
    } \
}
            MRB_CALL_ARG_STRUCT("{CGSize=dd}", CGSize, CGSizeValue);
            MRB_CALL_ARG_STRUCT("{CGPoint=dd}", CGPoint, CGPointValue);
            MRB_CALL_ARG_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, CGRectValue);
            MRB_CALL_ARG_STRUCT("{_NSRange=QQ}", NSRange, rangeValue);
            break;
        }
        default:
            break;
    }
}

+ (id)objectWithCValue:(void *)src forType:(const char *)typeString
{
    switch (typeString[0]) {
    #define MRB_FFI_RETURN_CASE(_typeString, _type, _selector)\
        case _typeString:{\
            _type v = *(_type *)src;\
            return [NSNumber _selector:v];\
        }
        MRB_FFI_RETURN_CASE('c', char, numberWithChar)
        MRB_FFI_RETURN_CASE('C', unsigned char, numberWithUnsignedChar)
        MRB_FFI_RETURN_CASE('s', short, numberWithShort)
        MRB_FFI_RETURN_CASE('S', unsigned short, numberWithUnsignedShort)
        MRB_FFI_RETURN_CASE('i', int, numberWithInt)
        MRB_FFI_RETURN_CASE('I', unsigned int, numberWithUnsignedInt)
        MRB_FFI_RETURN_CASE('l', long, numberWithLong)
        MRB_FFI_RETURN_CASE('L', unsigned long, numberWithUnsignedLong)
        MRB_FFI_RETURN_CASE('q', long long, numberWithLongLong)
        MRB_FFI_RETURN_CASE('Q', unsigned long long, numberWithUnsignedLongLong)
        MRB_FFI_RETURN_CASE('f', float, numberWithFloat)
        MRB_FFI_RETURN_CASE('d', double, numberWithDouble)
        MRB_FFI_RETURN_CASE('B', BOOL, numberWithBool)
        case '@':
        case '#': {
            return (__bridge id)(*(void**)src);
        }
        case '{': {
#define MRB_CALL_RET_STRUCT(_encode, _type, _selector) { \
            if (strcmp(typeString, _encode)==0) { \
                _type returnValue = (*(_type *)src); \
                return [NSValue _selector:returnValue]; \
            } \
        }
            
            MRB_CALL_RET_STRUCT("{CGSize=dd}", CGSize, valueWithCGSize)
            MRB_CALL_RET_STRUCT("{CGPoint=dd}", CGPoint, valueWithCGPoint)
            MRB_CALL_RET_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, valueWithCGRect)
            MRB_CALL_RET_STRUCT("{_NSRange=QQ}", NSRange, valueWithRange)
            
            return nil;
        }
        default:
            return nil;
    }
}

@end
