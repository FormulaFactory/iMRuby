//
//  MRBMethodSignature.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

// 该实现来自于JSPatch的JSBlock

#import <Foundation/Foundation.h>
#import "ffi.h"

@interface MRBMethodSignature : NSObject

@property (nonatomic, readonly) NSString *types;
@property (nonatomic, readonly) NSArray *argumentTypes;
@property (nonatomic, readonly) NSString *returnType;

- (instancetype)initWithObjCTypes:(NSString *)objCTypes;
- (instancetype)initWithBlockTypeNames:(NSString *)typeNames;
+ (ffi_type *)ffiTypeWithEncodingChar:(const char *)c;

+ (NSString *)typeEncodeWithTypeName:(NSString *)typeName;

@end
