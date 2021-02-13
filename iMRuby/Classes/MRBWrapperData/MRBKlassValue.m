//
//  MRBKlassValue.m
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBKlassValue.h"
#import "MRBContext.h"
#import <objc/runtime.h>

static mrb_data_type *cocoa_klass_type;

static void
cocoa_klass_destructor(mrb_state *mrb, void *p) {
    struct MRBCocoaKlassWrapper *klass = p;
    CFRelease(klass);
    mrb_free(mrb, p);
}

static struct mrb_data_type *
get_cocoa_klass_type(mrb_state *mrb) {
    if (cocoa_klass_type == NULL) {
        cocoa_klass_type = mrb_malloc(mrb, sizeof(mrb_data_type));
        cocoa_klass_type->struct_name = "CocoaKlass";
        cocoa_klass_type->dfree = cocoa_klass_destructor;
    }
    
    return cocoa_klass_type;
}

mrb_value
generate_klass(mrb_state *mrb, Class klass) {
    if (!object_isClass(klass)) {
        return mrb_nil_value();
    }
    mrb_data_type *cocoa_klass_type = get_cocoa_klass_type(mrb);
    struct MRBCocoaKlassWrapper *wrapperKlass = mrb_malloc(mrb, sizeof(struct MRBCocoaKlassWrapper));
    wrapperKlass->name = "Klass";
    wrapperKlass->class_name = [NSStringFromClass(klass) UTF8String];
    wrapperKlass->p = (__bridge void*)klass;
    wrapperKlass->mrb = mrb;
    CFRetain(wrapperKlass->p);
    struct RClass *cocoa_module = mrb_module_get(mrb, "MRBCocoa");
    struct RClass *mrKlass = mrb_class_get_under(mrb, cocoa_module, "Klass");
    mrb_value mrb_cocoa_klass = mrb_obj_value(Data_Wrap_Struct(mrb, mrKlass, cocoa_klass_type, wrapperKlass));
    return mrb_cocoa_klass;
}

struct MRBCocoaKlassWrapper *get_klass_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_klass) {
    mrb_data_type *cocoa_klass_type = get_cocoa_klass_type(mrb);
    
    struct MRBCocoaKlassWrapper *wrapperKlass = DATA_CHECK_GET_PTR(mrb, mrb_cocoa_klass, cocoa_klass_type, struct MRBCocoaKlassWrapper);
    return wrapperKlass;

}

id get_klass(mrb_state *mrb, mrb_value mrb_cocoa_klass) {
    enum mrb_vtype type = mrb_type(mrb_cocoa_klass);
    if (type != MRB_TT_DATA) {
        return nil;
    }
    struct MRBCocoaKlassWrapper *wrapperKlass = get_klass_wrapper_struct(mrb, mrb_cocoa_klass);
    id klass = nil;
    if (wrapperKlass != NULL) {
        klass = (__bridge id)wrapperKlass->p;
    }
    
    return klass;
}


@implementation MRBKlassValue

+ (mrb_value)generateMRBKlass:(Class)klass context:(MRBContext *)context
{
    return generate_klass(context.current_mrb, klass);
}

+ (id)getKlass:(mrb_value)mrbKlass context:(MRBContext *)context
{
    return get_klass(context.current_mrb, mrbKlass);
}


@end
