//
//  MRBContext.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import <Foundation/Foundation.h>
@import MRuby;

@class MRBValue;
@class MRBProcToBlock;

NS_ASSUME_NONNULL_BEGIN

@interface MRBContext : NSObject

@property (nonatomic, copy, nullable) void (^exceptionHandler)(NSError *exception);

- (MRBValue *)evaluateScript:(NSString *)script;
- (MRBValue *)callFunc:(NSString *)funcName args:(NSArray <MRBValue *> *)args;
- (MRBValue *)getRegisterFunc:(NSString *)funcName;
- (BOOL)registerFunc:(NSString *)funcName block:(id)block;
- (MRBValue *)getRegisterConst:(NSString *)constName;
- (BOOL)registerConst:(NSString *)constName value:(id)value;

@property (readonly) mrb_state *current_mrb;

+ (nullable MRBContext *)getMRBContextWithMrb:(mrb_state *)mrb;
- (void)mrbyException;

@end

@interface MRBContext (SubscriptSupport)

- (MRBValue *)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
