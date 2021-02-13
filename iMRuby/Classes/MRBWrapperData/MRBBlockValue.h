//
//  MRBBlockValue.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import <Foundation/Foundation.h>
@import MRuby;

@class MRBContext;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT mrb_value generate_block(mrb_state *mrb, id block);
FOUNDATION_EXPORT struct MRBCocoaBlockWrapper * get_block_wrapper_struct(mrb_state *mrb, mrb_value mrb_cocoa_block);
FOUNDATION_EXPORT id get_block(mrb_state *mrb, mrb_value mrb_cocoa_block);
FOUNDATION_EXPORT mrb_value block_call(mrb_state *mrb, mrb_value mrb_obj_self);

// proc to block
FOUNDATION_EXPORT mrb_value proc_to_block(mrb_state *mrb, mrb_value mrb_obj_self);

@interface MRBBlockValue : NSObject
+ (mrb_value)generateMRBBlock:(id)block context:(MRBContext *)context;
+ (nullable id)getBlock:(mrb_value)mrbBlock context:(MRBContext *)context;

+ (nullable NSMethodSignature *)getSignatureWithBlock:(id)block;

@end

@interface MRBProcToBlock : NSObject
- (id)initWithTypeString:(NSString *)typeString proc:(mrb_value)proc context:(MRBContext *)context;
- (void *)blockPtr;
@end

NS_ASSUME_NONNULL_END
