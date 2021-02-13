//
//  MRBObjectValue.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import <Foundation/Foundation.h>

@import MRuby;

@class MRBContext;

NS_ASSUME_NONNULL_BEGIN

typedef struct MRBCocoaObjectWrapper {
    const char *name;
    const char *class_name;
    void *p;
    mrb_state *mrb;
} MRBCocoaObjectWrapper;

FOUNDATION_EXPORT mrb_value generate_object(mrb_state *mrb, id object);
FOUNDATION_EXPORT struct MRBCocoaObjectWrapper *get_object_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_object);
FOUNDATION_EXPORT id get_object(mrb_state *mrb, mrb_value mrb_cocoa_object);

@interface MRBObjectValue : NSObject

+ (mrb_value)generateMRBObject:(id)object context:(MRBContext *)context;
+ (nullable id)getObject:(mrb_value)mrbObject context:(MRBContext *)context;

@end

NS_ASSUME_NONNULL_END
