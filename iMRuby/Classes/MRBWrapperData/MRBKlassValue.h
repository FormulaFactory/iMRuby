//
//  MRBKlassValue.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//


#import <Foundation/Foundation.h>
@import MRuby;
@class MRBContext;

NS_ASSUME_NONNULL_BEGIN

typedef struct MRBCocoaKlassWrapper {
    const char *name;
    const char *class_name;
    void *p;
    mrb_state *mrb;
} MRBCocoaKlassWrapper;

FOUNDATION_EXPORT mrb_value generate_klass(mrb_state *mrb, Class klass);
FOUNDATION_EXPORT struct MRBCocoaKlassWrapper *get_klass_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_klass);
FOUNDATION_EXPORT Class get_klass(mrb_state *mrb, mrb_value mrb_cocoa_klass);

@interface MRBKlassValue : NSObject

+ (mrb_value)generateMRBKlass:(Class)klass context:(MRBContext *)context;

+ (id)getKlass:(mrb_value)mrbKlass context:(MRBContext *)context;

@end

NS_ASSUME_NONNULL_END
