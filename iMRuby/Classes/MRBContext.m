//
//  MRBContext.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBContext.h"
#import "MRBValue.h"
#import "MRBBlockValue.h"
#import <objc/runtime.h>
#import "MRBBlockInvocation.h"
#import "MRBMethodInvocation.h"
#import "MRBCFunc.h"

static NSHashTable *_mRBContextHashTable;

@interface MRBContext()

@property (class, atomic, strong) NSHashTable *mRBContextHashTable;
@property (nonatomic, strong) NSMutableDictionary <NSString *, id> *registerFuncs;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *defineCFuncs;

@end

static mrb_value register_func_call(mrb_state *mrb, mrb_value mrb_obj_self) {
    MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
    mrb_value *argv = mrb_get_argv(mrb);
    mrb_int argc = mrb_get_argc(mrb);
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:argc];
    id block;
    for (int i=0; i < argc; i++) {
        mrb_value mrbv = argv[i];
        id obj = [MRBValue convertToObjectWithMrbValue:mrbv inContext:context];
        if (i==0) { // method_name
            block = [context.registerFuncs objectForKey:obj];
        } else {
            [args addObject:obj];
        }
    }
    
    if (!block) {
        // TODO: throw exception
        return mrb_nil_value();
    }
    
    NSMethodSignature *sign = [MRBBlockValue getSignatureWithBlock:block];
    if (!sign) {
        return mrb_nil_value();
    }
    MRBBlockInvocation *inv = [[MRBBlockInvocation alloc] initWithTarget:block sign:sign];
    [inv setArguments:args];
    id returnValue = [inv invokeAndReturn];
    if (!returnValue) {
        return mrb_nil_value();
    }
    MRBValue *returnMrbValue = [MRBValue convertToMRBValueWithObj:returnValue inContext:context];
    return returnMrbValue.mrb_value;
}

static mrb_value cocoa_export_methods(mrb_state *mrb, mrb_value mrb_obj_self) {
    MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
    // target
    MRBValue *mrbTarget = [MRBValue valueWithMrbValue:mrb_obj_self inContext:context];
    id target = nil;
    if (mrbTarget.isKlass) {
        target = mrbTarget.toKlass;
    } else if (mrbTarget.isObject) {
        target = mrbTarget.toObject;
    }
    if (!target) {
        return mrb_nil_value();
    }
    
    mrb_value *argv = mrb_get_argv(mrb);
    mrb_int argc = mrb_get_argc(mrb);
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:argc];
    SEL selector = NULL;
    NSMethodSignature *sign;
    NSString *methodName;
    for (int i=0; i < argc; i++) {
        mrb_value mrbv = argv[i];
        id obj = [MRBValue convertToObjectWithMrbValue:mrbv inContext:context];
        methodName = obj;
        if (i==0) { // method_name
            selector = NSSelectorFromString(obj);
            if (mrbTarget.isObject) {
                sign = [[target class] instanceMethodSignatureForSelector:selector];
            } else {
                sign = [target methodSignatureForSelector:selector];
            }
        } else {
            [args addObject:obj];
        }
    }
    
    if (!sign) {
        // TODO: throw exception
        return mrb_nil_value();
    }
    
    MRBMethodInvocation *inv = [[MRBMethodInvocation alloc] initWithTarget:target sign:sign];
    inv.selector = selector;
    [inv setArguments:args];
    id returnValue = [inv invokeAndReturn];
    if (!returnValue) {
        return  mrb_nil_value();
    }
    MRBValue *returnMrbValue = [MRBValue convertToMRBValueWithObj:returnValue inContext:context];
    return returnMrbValue.mrb_value;
}

static mrb_value require_cocoa(mrb_state *mrb, mrb_value mrb_obj_self) {
    char *klass_name;
    mrb_get_args(mrb, "z", &klass_name);
    Class klass = NSClassFromString([NSString stringWithCString:klass_name encoding:NSUTF8StringEncoding]);
    if (!klass) {
        // 报错
        return mrb_nil_value();
    }
    MRBValue *mrbValue = [MRBValue valueWithKlass:klass inContext:[MRBContext getMRBContextWithMrb:mrb]];
    mrb_define_const(mrb, mrb->kernel_module, klass_name, mrbValue.mrb_value);
    return mrb_nil_value();
}

static mrb_value define_cfunc(mrb_state *mrb, mrb_value mrb_obj_self) {
    
    MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
    
    char *name;
    char *encode;
    mrb_get_args(mrb, "zz", &name ,&encode);
    NSString *encodeStr = [MRBCFunc getEncodeStrWithTypes:[NSString stringWithCString:encode encoding:NSUTF8StringEncoding]];
    NSString *cfuncName = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
    
    if (!encodeStr || !cfuncName) {
        return mrb_false_value();
    }
    
    [context.defineCFuncs setObject:encodeStr forKey:cfuncName];
    return mrb_true_value();
}

static mrb_value cfunc_call(mrb_state *mrb, mrb_value mrb_obj_self) {
    // ruby --> objc --> ffi --> ffi return --> objc --> ruby
    MRBContext *context = [MRBContext getMRBContextWithMrb:mrb];
    
    mrb_value *argv = mrb_get_argv(mrb);
    mrb_int argc = mrb_get_argc(mrb);
    NSMutableArray *args = [[NSMutableArray alloc] initWithCapacity:argc];
    NSString *funcName;
    
    for (int i=0; i < argc; i++) {
        mrb_value mrbv = argv[i];
        id obj = [MRBValue convertToObjectWithMrbValue:mrbv inContext:context];
        if (i==0) { // func_name
            funcName = obj;
        } else {
            [args addObject:obj];
        }
    }
    
    id ret = [MRBCFunc callCFunc:funcName args:args encode:[context.defineCFuncs objectForKey:funcName]];
    if (!ret) {
        return mrb_nil_value();
    }
    
    MRBValue *mrbValue = [MRBValue convertToMRBValueWithObj:ret inContext:context];
    return mrbValue.mrb_value;
}

@implementation MRBContext {
    mrb_state *mrb;
    mrbc_context *ctx;
}

+ (void)load
{
    self.mRBContextHashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
}

- (void)dealloc
{
    mrbc_context_free(mrb, ctx);
    mrb_close(mrb);
}

+ (nullable MRBContext *)getMRBContextWithMrb:(mrb_state *)mrb
{
    __block MRBContext *currentContext = nil;
    @synchronized(NSObject.class) {
        NSArray <MRBContext *> *contexts = [[self mRBContextHashTable] allObjects];
        [contexts enumerateObjectsUsingBlock:^(MRBContext * _Nonnull context, NSUInteger idx, BOOL * _Nonnull stop) {
            mrb_state *mrb_r = context.current_mrb;
            if (mrb_r == mrb) {
                currentContext = context;
            }
        }];
    }
    
    return currentContext;
}

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;
    _registerFuncs = [[NSMutableDictionary alloc] init];
    _defineCFuncs = [[NSMutableDictionary alloc] init];
    [[[self class] mRBContextHashTable] addObject:self];
    mrb = mrb_open();
    ctx = mrbc_context_new(mrb);
    [self loadMainRuby];
    return self;
}

- (MRBValue *)evaluateScript:(NSString *)script
{
    const char *s = [script UTF8String];
    mrb_value result = mrb_load_string_cxt(mrb, s, ctx);
    if (mrb->exc) {
        [self mrbyException];
    }
    return [MRBValue valueWithMrbValue:result inContext:self];
}

- (mrb_state *)current_mrb
{
    return mrb;
}

- (MRBValue *)callFunc:(NSString *)funcName args:(NSArray <MRBValue *> *)args
{
    mrb_value argv[args.count];
    for (int i=0; i < args.count; i++) {
        MRBValue *value = args[i];
        argv[i] = value.mrb_value;
    }
    struct RClass *mrb_cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    mrb_value mrbv;
    if (args.count>0) {
        mrbv = mrb_funcall_argv(mrb, mrb_obj_value(mrb_cocoa_module), mrb_intern_cstr(mrb, [funcName UTF8String]), args.count, &(argv[0]));
    } else {
        mrbv = mrb_funcall(mrb, mrb_obj_value(mrb_cocoa_module), [funcName UTF8String], 0);
    }
    if (mrb->exc) {
        [self mrbyException];
    }
    return [MRBValue valueWithMrbValue:mrbv inContext:self];
}

- (BOOL)registerFunc:(NSString *)funcName block:(id)block
{
    if (!block || funcName.length==0) {
        return NO;
    }
    
    NSString *block_class_name = NSStringFromClass([block class]);
    if (![block_class_name isEqualToString:@"__NSGlobalBlock__"] &&
        ![block_class_name isEqualToString:@"__NSMallocBlock__"] &&
        ![block_class_name isEqualToString:@"__NSStackBlock__"]) {
        // TODO: throw exception
        return NO;
    }
    
    [self.registerFuncs setObject:block forKey:funcName];
    return YES;
}

- (BOOL)registerConst:(NSString *)constName value:(id)value
{
    MRBValue *mrbValue = [MRBValue convertToMRBValueWithObj:value inContext:self];
    struct RClass *mrb_cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *mrb_const_module = mrb_module_get_under(mrb, mrb_cocoa_module, "Const");
    mrb_define_const(mrb, mrb_const_module, [constName UTF8String], mrbValue.mrb_value);
    if (mrb->exc) {
        [self mrbyException];
        return NO;
    }
    return YES;
}

- (MRBValue *)getRegisterFunc:(NSString *)funcName
{
    id func = [self.registerFuncs objectForKey:funcName];
    return [MRBValue convertToMRBValueWithObj:func inContext:self];
}

- (MRBValue *)getRegisterConst:(NSString *)constName
{
    struct RClass *mrb_cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *mrb_const_module = mrb_module_get_under(mrb, mrb_cocoa_module, "Const");
    mrb_value value = mrb_const_get(mrb, mrb_obj_value(mrb_const_module), mrb_intern_cstr(mrb, [constName UTF8String]));
    return [MRBValue valueWithMrbValue:value inContext:self];
}

#pragma -
+ (void)setMRBContextHashTable:(NSHashTable *)mRBContextHashTable
{
    _mRBContextHashTable = mRBContextHashTable;
}

+ (NSHashTable *)mRBContextHashTable
{
    return _mRBContextHashTable;
}

#pragma mark - private
- (void)mrbyException
{
    mrb_value backtrace;
     if (!mrb->exc) {
       return;
     }
     backtrace = mrb_obj_iv_get(mrb, mrb->exc, mrb_intern_lit(mrb, "backtrace"));
    if (mrb_nil_p(backtrace)) return;
    if (!mrb_array_p(backtrace)) backtrace = mrb_get_backtrace(mrb);
    
    mrb_int i;
    mrb_int n = RARRAY_LEN(backtrace);
    mrb_value *loc, mesg;
    mrb_value exc = mrb_obj_value(mrb->exc);

    NSString *errorMsg = @"";
    if (n != 0) {
      errorMsg = @"trace (most recent call last):\n";
      for (i=n-1,loc=&RARRAY_PTR(backtrace)[i]; i>0; i--,loc--) {
        if (mrb_string_p(*loc)) {
           const char* c = mrb_string_cstr(mrb, *loc);
            errorMsg = [errorMsg stringByAppendingString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
        }
      }
      if (mrb_string_p(*loc)) {
          const char* c = mrb_string_cstr(mrb, *loc);
          errorMsg = [errorMsg stringByAppendingString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
      }
    }
    mesg = mrb_attr_get(mrb, exc, mrb_intern_lit(mrb, "mesg"));
    mrb_value cname = mrb_mod_to_s(mrb, mrb_obj_value(mrb_obj_class(mrb, exc)));
    mesg = mrb_obj_as_string(mrb, mesg);
    mesg = RSTRING_LEN(mesg) == 0 ? cname : mrb_format(mrb, "%v (%v)", mesg, cname);
    
    const char* c = mrb_string_cstr(mrb, mesg);
    errorMsg = [errorMsg stringByAppendingString:[NSString stringWithCString:c encoding:NSUTF8StringEncoding]];
    
    if (self.exceptionHandler) {
        NSError *err = [NSError errorWithDomain:@"iMRuby" code:9999 userInfo:@{@"msg": errorMsg}];
        self.exceptionHandler(err);
    }
}

- (void)loadMainRuby
{
    NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
    NSBundle *resourceBundle = [NSBundle bundleWithPath:[mainBundle pathForResource:@"iMRuby" ofType:@"bundle"]];
    NSString *mainPath = [resourceBundle pathForResource:@"main" ofType:@"rb"];
    NSError *error;
    NSString *mainScript = [NSString stringWithContentsOfFile:mainPath encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSAssert(NO, @"load main ruby code error");
        return;;
    }
    
    [self evaluateScript:mainScript];
    
    // add call methods in MRBCocoa::Block
    struct RClass *mrb_cocoa_modlue = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *mrb_block_class = mrb_class_get_under(mrb, mrb_cocoa_modlue, "Block");
    mrb_define_method(mrb, mrb_block_class, "call", block_call, MRB_ARGS_ANY());
    
    // add register methods in MRBCocoa::Func
    // struct RClass *mrb_func_module = mrb_module_get_under(mrb, mrb_cocoa_modlue, "Func");
    mrb_define_module_function(mrb, mrb_cocoa_modlue, "register_func_call", register_func_call, MRB_ARGS_ANY());
    
    // export cocoa obj methods
    struct RClass *mrb_object_class = mrb_class_get_under(mrb, mrb_cocoa_modlue, "Object");
    mrb_define_module_function(mrb, mrb_object_class, "cocoa_export_method", cocoa_export_methods, MRB_ARGS_ANY());
    
    // export cocoa klass methods
    struct RClass *mrb_klass_class = mrb_class_get_under(mrb, mrb_cocoa_modlue, "Klass");
    mrb_define_module_function(mrb, mrb_klass_class, "cocoa_export_method", cocoa_export_methods, MRB_ARGS_ANY());
    
    // require cocoa class
    mrb_define_method(mrb, mrb->kernel_module, "require_cocoa", require_cocoa, MRB_ARGS_REQ(1));
    
    // proc
    struct RClass *mrb_proc_class = mrb_class_get(mrb, "Proc");
    mrb_define_method(mrb, mrb_proc_class, "to_cocoa_block", proc_to_block, MRB_ARGS_REQ(1));
    
    // define c func
    mrb_define_module_function(mrb, mrb_cocoa_modlue, "define_cfunc", define_cfunc, MRB_ARGS_REQ(2));
    // call c func
    mrb_define_module_function(mrb, mrb_cocoa_modlue, "cfunc_call", cfunc_call, MRB_ARGS_ANY());

}
@end

@implementation MRBContext (SubscriptSupport)

- (MRBValue *)objectForKeyedSubscript:(NSString *)key
{
    MRBValue *value = [self getRegisterConst:key];
    if (value) {
        return value;
    }
    return [self getRegisterConst:key];
}

- (void)setObject:(id)object forKeyedSubscript:(NSString *)key
{
    NSString *object_class_name = NSStringFromClass([object class]);
    if ([object_class_name isEqualToString:@"__NSGlobalBlock__"] ||
        [object_class_name isEqualToString:@"__NSMallocBlock__"] ||
        [object_class_name isEqualToString:@"__NSStackBlock__"]) {
        [self registerFunc:key block:object];
        return;
    }
    [self registerConst:key value:object];
}

@end
