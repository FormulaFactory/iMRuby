//
//  MRBObjectValue.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBObjectValue.h"
#import "MRBContext.h"
#import <objc/runtime.h>

static mrb_data_type *cocoa_object_type;

static void
cocoa_object_destructor(mrb_state *mrb, void *p) {
    struct MRBCocoaObjectWrapper *object = p;
    CFRelease(object->p);
    mrb_free(mrb, p);
}

static struct mrb_data_type *
get_cocoa_object_type(mrb_state *mrb) {
    if (cocoa_object_type == NULL) {
        cocoa_object_type = mrb_malloc(mrb, sizeof(mrb_data_type));
        cocoa_object_type->struct_name = "CocoaObject";
        cocoa_object_type->dfree = cocoa_object_destructor;
    }
    
    return cocoa_object_type;
}

mrb_value
generate_object(mrb_state *mrb, id object) {
    if (object_isClass(object)) {
        return mrb_nil_value();
    }
    
    if ([object isKindOfClass:NSString.class] ||
        [object isKindOfClass:NSNumber.class] ||
        [object isKindOfClass:NSDictionary.class] ||
        [object isKindOfClass:NSArray.class] ||
        [object isKindOfClass:NSDate.class]) {
        return mrb_nil_value();
    }
    
    NSString *object_class_name = NSStringFromClass([object class]);
    if ([object_class_name isEqualToString:@"__NSGlobalBlock__"] ||
        [object_class_name isEqualToString:@"__NSMallocBlock__"] ||
        [object_class_name isEqualToString:@"__NSStackBlock__"]) {
        return mrb_nil_value();
    }
    
    mrb_data_type *cocoa_object_type = get_cocoa_object_type(mrb);
    struct MRBCocoaObjectWrapper *wrapperObject = mrb_malloc(mrb, sizeof(struct MRBCocoaObjectWrapper));
    wrapperObject->class_name = [NSStringFromClass([object class]) UTF8String];
    wrapperObject->name = "Object";
    wrapperObject->p = (__bridge void*)object;
    wrapperObject->mrb = mrb;
    // 防止原生对象已经被ARC回收,但ruby还在使用
    CFRetain(wrapperObject->p);
    struct RClass *cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *klass = mrb_class_get_under(mrb, cocoa_module, "Object");
    mrb_value mrb_cocoa_object = mrb_obj_value(Data_Wrap_Struct(mrb, klass, cocoa_object_type, wrapperObject));
    return mrb_cocoa_object;
}

struct MRBCocoaObjectWrapper *get_object_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_object) {
    mrb_data_type *cocoa_object_type = get_cocoa_object_type(mrb);
    
    struct MRBCocoaObjectWrapper *wrapperObject = DATA_CHECK_GET_PTR(mrb, mrb_cocoa_object, cocoa_object_type, struct MRBCocoaObjectWrapper);
    return wrapperObject;

}

id get_object(mrb_state *mrb, mrb_value mrb_cocoa_object) {
    enum mrb_vtype type = mrb_type(mrb_cocoa_object);
    if (type != MRB_TT_DATA) {
        return nil;
    }
    struct MRBCocoaObjectWrapper *wrapperObject = get_object_wrapper_struct(mrb, mrb_cocoa_object);
    id object = nil;
    if (wrapperObject != NULL) {
        object = (__bridge id)wrapperObject->p;
    }
    return object;
}


@implementation MRBObjectValue

+ (mrb_value)generateMRBObject:(id)object context:(MRBContext *)context
{
    return generate_object(context.current_mrb, object);
}

+ (nullable id)getObject:(mrb_value)mrbObject context:(MRBContext *)context
{
    return get_object(context.current_mrb, mrbObject);
}


@end
