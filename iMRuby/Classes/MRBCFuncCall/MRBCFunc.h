//
//  MRBCFunc.h
//  iMRuby
//
//  Created by ping.cao on 2021/3/19.
//

// 该实现来自于JSPatch的JPCFunction

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MRBCFunc : NSObject

+ (nullable NSString *)getEncodeStrWithTypes:(NSString *)types;
+ (id)callCFunc:(NSString *)funcName args:(NSArray *)args encode:(NSString *)encode;

@end

NS_ASSUME_NONNULL_END
