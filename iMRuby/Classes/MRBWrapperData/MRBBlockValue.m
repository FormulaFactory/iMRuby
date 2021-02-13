//
//  MRBBlockValue.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBBlockValue.h"
#import "MRBContext.h"
#import "MRBValue.h"
#import "MRBBlockInvocation.h"
#import "ffi.h"
#import "MRBMethodSignature.h"

typedef struct MRBCocoaBlockWrapper {
    const char *name;
    void *sign;
    void *p;
    mrb_state *mrb;
} MRBCocoaBlockWrapper;

typedef struct MRBBlockDescriptor {
    unsigned long int reserved;
    unsigned long int size;
    void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
    void (*dispose_helper)(void *src);             // IFF (1<<25)
    const char *signature;                         // IFF (1<<30)
 } MRBBlockDescriptor;

// define block struct
typedef struct MRBBlockLiteral {
    void *isa;
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct MRBBlockDescriptor *descriptor;
    void *procToBlock;
 } MRBBlockLiteral;

 // flags enum
 enum {
     MRBBlockDescriptionFlagsHasCopyDispose = (1 << 25),
     MRBBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
     MRBBlockDescriptionFlagsIsGlobal = (1 << 28),
     MRBBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
     MRBBlockDescriptionFlagsHasSignature = (1 << 30)
 };

typedef int MRBBlockDescriptionFlags;

void copy_helper(struct MRBBlockLiteral *dst, struct MRBBlockLiteral *src)
{
    if (dst->procToBlock != NULL) {
        CFRetain(dst->procToBlock);
    }
}

void dispose_helper(struct MRBBlockLiteral *src)
{
    if (src->procToBlock != NULL) {
        CFRelease(src->procToBlock);
    }
}

@interface MRBBlockValue()

+ (NSMethodSignature *)getSignatureWithBlock:(id)block;

@end

struct mrb_data_type *cocoa_block_type;

static void
cocoa_block_destructor(mrb_state *mrb, void *p) {
    struct MRBCocoaBlockWrapper *block = p;
    CFRelease(block->p);
    mrb_free(mrb, p);
}

static struct mrb_data_type *
get_cocoa_block_type(mrb_state *mrb) {
    if (cocoa_block_type == NULL) {
        cocoa_block_type = mrb_malloc(mrb, sizeof(mrb_data_type));
        cocoa_block_type->struct_name = "CocoaBlock";
        cocoa_block_type->dfree = cocoa_block_destructor;
    }
    return  cocoa_block_type;
}

mrb_value
generate_block(mrb_state *mrb, id block) {
    NSString *block_class_name = NSStringFromClass([block class]);
    if (![block_class_name isEqualToString:@"__NSGlobalBlock__"] &&
        ![block_class_name isEqualToString:@"__NSMallocBlock__"] &&
        ![block_class_name isEqualToString:@"__NSStackBlock__"]) {
        return mrb_nil_value();
    }
    
    struct MRBCocoaBlockWrapper *wrapperBlock = mrb_alloca(mrb, sizeof(struct MRBCocoaBlockWrapper));
    wrapperBlock->name = "Block";
    wrapperBlock->p = (__bridge  void*)block;
    wrapperBlock->mrb = mrb;
    NSMethodSignature *sign = [MRBBlockValue getSignatureWithBlock:block];
    if (!sign) {
        //NSAssert(NO, @"generate block error , sign");
    }
    wrapperBlock->sign = (__bridge void*)sign;
    
    mrb_data_type *cocoa_block_type = get_cocoa_block_type(mrb);
    
    struct RClass *cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *klass = mrb_class_get_under(mrb, cocoa_module, "Block");
    mrb_value mrb_cocoa_block = mrb_obj_value(Data_Wrap_Struct(mrb, klass, cocoa_block_type, wrapperBlock));
    CFRetain(wrapperBlock->p);
    return mrb_cocoa_block;
}

struct MRBCocoaBlockWrapper * get_block_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_block) {
    mrb_data_type *cocoa_block_type = get_cocoa_block_type(mrb);
    
    struct MRBCocoaBlockWrapper *wrapperBlock = DATA_CHECK_GET_PTR(mrb, mrb_cocoa_block, cocoa_block_type, struct MRBCocoaBlockWrapper);
    return wrapperBlock;
};

id get_block(mrb_state *mrb, mrb_value mrb_cocoa_block) {
    enum mrb_vtype type = mrb_type(mrb_cocoa_block);
    if (type != MRB_TT_DATA) {
        return nil;
    }
    struct MRBCocoaBlockWrapper *wrapperBlock = get_block_wrapper_struct(mrb, mrb_cocoa_block);
    id block = nil;
    if (wrapperBlock != NULL) {
        block = (__bridge id)wrapperBlock->p;
    }
    return block;
}


mrb_value block_call(mrb_state *mrb, mrb_value mrb_obj_self) {
    MRBCocoaBlockWrapper *block_wrapper = get_block_wrapper_struct(mrb, mrb_obj_self);
    NSMethodSignature *sign = (__bridge id)block_wrapper->sign;
    
    if (sign) {
        MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
        mrb_int argc = mrb_get_argc(mrb);
        mrb_value *argv = mrb_get_argv(mrb);
        NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:argc];
        for(int i = 0; i < argc; i++) {
            mrb_value mrbv = argv[i];
            id obj = [MRBValue convertToObjectWithMrbValue:mrbv inContext:context];
            [args addObject:obj];
        }
        
        id block = (__bridge id)block_wrapper->p;
        MRBBlockInvocation *inv = [[MRBBlockInvocation alloc] initWithTarget:block sign:sign];
        [inv setArguments:args];
        id returnValue = [inv invokeAndReturn];
        if (!returnValue) {
            return mrb_nil_value();
        }
        MRBValue *returnMrbValue = [MRBValue convertToMRBValueWithObj:returnValue inContext:context];
        return returnMrbValue.mrb_value;
    }
        
    return mrb_nil_value();
}

@implementation MRBBlockValue

#pragma mark -
+ (mrb_value)generateMRBBlock:(id)block context:(MRBContext *)context
{
    return generate_block(context.current_mrb, block);
}

+ (id)getBlock:(mrb_value)mrbBlock context:(MRBContext *)context
{
    return get_block(context.current_mrb, mrbBlock);
}

#pragma mark -
+ (NSMethodSignature *)getSignatureWithBlock:(id)block{
    struct MRBBlockLiteral *blockRef = (__bridge struct MRBBlockLiteral *)block;
    MRBBlockDescriptionFlags _flags = blockRef->flags;
    if (_flags & MRBBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (_flags & MRBBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *signature = (*(const char **)signatureLocation);
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return nil;
}

@end

@interface MRBProcToBlock()  {
    ffi_cif *_cifPtr;
    ffi_type **_args;
    ffi_closure *_closure;
    void *_blockPtr;
    struct MRBBlockDescriptor *_descriptor;
}

@property (nonatomic, strong) MRBMethodSignature *signature;
@property (nonatomic, weak) MRBContext *context;
@property (nonatomic, assign) mrb_value proc;

@end

void MRBBlockInterpreter(ffi_cif *cif, void *ret, void **args, void *userdata) {
    
    MRBProcToBlock *procToBlock = (__bridge MRBProcToBlock *)userdata;
    NSInteger argsCount = procToBlock.signature.argumentTypes.count;
    mrb_value argv[argsCount-1];
    for (int i = 1; i < argsCount; i ++) {
        id param;
        void *argumentPtr = args[i];
        const char *typeEncoding = [procToBlock.signature.argumentTypes[i] UTF8String];
        switch (typeEncoding[0]) {
                
        #define MRB_BLOCK_PARAM_CASE(_typeString, _type, _selector) \
            case _typeString: {                              \
                _type returnValue = *(_type *)argumentPtr;                     \
                param = [NSNumber _selector:returnValue];\
                break; \
            }
                MRB_BLOCK_PARAM_CASE('c', char, numberWithChar)
                MRB_BLOCK_PARAM_CASE('C', unsigned char, numberWithUnsignedChar)
                MRB_BLOCK_PARAM_CASE('s', short, numberWithShort)
                MRB_BLOCK_PARAM_CASE('S', unsigned short, numberWithUnsignedShort)
                MRB_BLOCK_PARAM_CASE('i', int, numberWithInt)
                MRB_BLOCK_PARAM_CASE('I', unsigned int, numberWithUnsignedInt)
                MRB_BLOCK_PARAM_CASE('l', long, numberWithLong)
                MRB_BLOCK_PARAM_CASE('L', unsigned long, numberWithUnsignedLong)
                MRB_BLOCK_PARAM_CASE('q', long long, numberWithLongLong)
                MRB_BLOCK_PARAM_CASE('Q', unsigned long long, numberWithUnsignedLongLong)
                MRB_BLOCK_PARAM_CASE('f', float, numberWithFloat)
                MRB_BLOCK_PARAM_CASE('d', double, numberWithDouble)
                MRB_BLOCK_PARAM_CASE('B', BOOL, numberWithBool)
            
            case '{':
            {
#define MRB_BLOCK_PARAM_STRUCT(_typeEncoding, _type, _selector) \
        if (strcmp(typeEncoding, _typeEncoding)==0) {\
        _type paramValue = *(_type *)argumentPtr; \
        param = [NSValue _selector:paramValue]; \
    }
                
                MRB_BLOCK_PARAM_STRUCT("{CGSize=dd}", CGSize, valueWithCGSize);
                MRB_BLOCK_PARAM_STRUCT("{CGPoint=dd}", CGPoint, valueWithCGPoint);
                MRB_BLOCK_PARAM_STRUCT("{_NSRange=QQ}", NSRange, valueWithRange);
                MRB_BLOCK_PARAM_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, valueWithCGRect);
                break;
            }
            case '#':
            case '@': {
                param = (__bridge id)(*(void**)argumentPtr);
                break;
            }
        }
        MRBValue *mrbValue = [MRBValue convertToMRBValueWithObj:param inContext:procToBlock.context];
        argv[i-1] = mrbValue.mrb_value;
    }
    
    mrb_value mrbv;
    mrb_state *mrb = procToBlock.context.current_mrb;
    if (argsCount>1) {
        mrbv = mrb_funcall_argv(mrb, procToBlock.proc, mrb_intern_cstr(mrb, "call"), argsCount, &(argv[0]));
    } else {
        mrbv = mrb_funcall(mrb, procToBlock.proc, "call", 0);
    }
    if (mrb->exc) {
        [procToBlock.context mrbyException];
    }
    
    MRBValue *returnValue = [MRBValue valueWithMrbValue:mrbv inContext:procToBlock.context];
    
    switch ([procToBlock.signature.returnType UTF8String][0]) {
                
        #define MRB_BLOCK_RET_CASE(_typeString, _type, _selector) \
            case _typeString: {                              \
                _type *retPtr = ret; \
                *retPtr = [((NSNumber *)[returnValue toNumber]) _selector];   \
                break; \
            }
            
            MRB_BLOCK_RET_CASE('c', char, charValue)
            MRB_BLOCK_RET_CASE('C', unsigned char, unsignedCharValue)
            MRB_BLOCK_RET_CASE('s', short, shortValue)
            MRB_BLOCK_RET_CASE('S', unsigned short, unsignedShortValue)
            MRB_BLOCK_RET_CASE('i', int, intValue)
            MRB_BLOCK_RET_CASE('I', unsigned int, unsignedIntValue)
            MRB_BLOCK_RET_CASE('l', long, longValue)
            MRB_BLOCK_RET_CASE('L', unsigned long, unsignedLongValue)
            MRB_BLOCK_RET_CASE('q', long long, longLongValue)
            MRB_BLOCK_RET_CASE('Q', unsigned long long, unsignedLongLongValue)
            MRB_BLOCK_RET_CASE('f', float, floatValue)
            MRB_BLOCK_RET_CASE('d', double, doubleValue)
            MRB_BLOCK_RET_CASE('B', BOOL, boolValue)
            
            
            case '{':
            case '@':
            case '#': {
                
                id retObj = [MRBValue convertToObjectWithMrbValue:returnValue.mrb_value inContext:procToBlock.context];
                if ([retObj isKindOfClass:[NSValue class]]) {
                     const char* type = [(NSValue *)retObj objCType];
                    
            #define MRB_BLOCK_RET_STRUCT(_objCType, _type, _selector) \
                if(strcmp(type, _objCType)==0) { \
                    _type (*retPtr) = ret; \
                    _type value = [(NSValue *)retObj _selector]; \
                    *retPtr = value; \
                }
                    
                    MRB_BLOCK_RET_STRUCT("{CGSize=dd}", CGSize, CGSizeValue);
                    MRB_BLOCK_RET_STRUCT("{CGPoint=dd}", CGPoint, CGPointValue);
                    MRB_BLOCK_RET_STRUCT("{_NSRange=QQ}", NSRange, rangeValue);
                    MRB_BLOCK_RET_STRUCT("{CGRect={CGPoint=dd}{CGSize=dd}}", CGRect, CGRectValue);
                } else {
                    void **retPtrPtr = ret;
                    *retPtrPtr = (__bridge void *)retObj;
                }
                break;
            }
        }
}

mrb_value proc_to_block(mrb_state *mrb, mrb_value mrb_obj_self) {

    if (!mrb_proc_p(mrb_obj_self)) {
        // 报错
        return mrb_nil_value();
    }
    
    char *encode;
    mrb_get_args(mrb, "z", &encode);
    
    MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
    MRBProcToBlock *blockValue = [[MRBProcToBlock alloc] initWithTypeString:[NSString stringWithCString:encode encoding:NSUTF8StringEncoding] proc:mrb_obj_self context:context];
    void *blockPtr = [blockValue blockPtr];
    mrb_value b = generate_block(mrb, (__bridge id)blockPtr);
    return b;
}


@implementation MRBProcToBlock

- (void)dealloc
{
    ffi_closure_free(_closure);
    free(_args);
    free(_cifPtr);
    free(_descriptor);
    return;
}

- (id)initWithTypeString:(NSString *)typeString proc:(mrb_value)proc context:(MRBContext *)context
{
    self = [super init];
    if(self) {
        self.signature = [[MRBMethodSignature alloc] initWithBlockTypeNames:typeString];
        self.proc = proc;
        self.context = context;
    }
    return self;
}

- (void *)blockPtr
{
    if (_blockPtr != NULL) {
        return _blockPtr;
    }
    ffi_type *returnType = [MRBMethodSignature ffiTypeWithEncodingChar:[self.signature.returnType UTF8String]];
    NSUInteger argumentCount = self.signature.argumentTypes.count;
    
    _cifPtr = malloc(sizeof(ffi_cif));
    
    void *blockImp = NULL;
    
    _args = malloc(sizeof(ffi_type *) *argumentCount) ;
    
    for (int i = 0; i < argumentCount; i++){
        ffi_type* current_ffi_type = [MRBMethodSignature ffiTypeWithEncodingChar:[self.signature.argumentTypes[i] UTF8String]];
        _args[i] = current_ffi_type;
    }
    
    _closure = ffi_closure_alloc(sizeof(ffi_closure), (void **)&blockImp);
    
    if(ffi_prep_cif(_cifPtr, FFI_DEFAULT_ABI, (unsigned int)argumentCount, returnType, _args) == FFI_OK) {
        if (ffi_prep_closure_loc(_closure, _cifPtr, MRBBlockInterpreter, (__bridge void *)self, blockImp) != FFI_OK) {
            NSAssert(NO, @"generate block error");
        }
    }
    
    struct MRBBlockDescriptor descriptor = {
        0,
        sizeof(struct MRBBlockLiteral),
        (void (*)(void *dst,void *src))copy_helper,
        (void (*)(void *src))dispose_helper,
        [self.signature.types cStringUsingEncoding:NSASCIIStringEncoding]
    };
    
    _descriptor = malloc(sizeof(struct MRBBlockDescriptor));
    memcpy(_descriptor, &descriptor, sizeof(struct MRBBlockDescriptor));
    
    struct MRBBlockLiteral block = {
        &_NSConcreteGlobalBlock,
        (MRBBlockDescriptionFlagsHasCopyDispose | MRBBlockDescriptionFlagsHasSignature),
        0,
        blockImp,
        _descriptor,
        (__bridge void *)self,
    };

    _blockPtr = Block_copy(&block);
    
    return _blockPtr;
}

@end
