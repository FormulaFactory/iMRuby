//
//  MRBInvocation.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MRBInvocation : NSObject

@property (nonatomic, strong) id target;
@property (nonatomic, strong) NSMethodSignature *sign;
@property (nonatomic, strong) NSArray *arguments;


- (instancetype)initWithTarget:(id)target sign:(NSMethodSignature *)sign;
- (nullable id)invokeAndReturn;

- (void)setArgument:(id)arg
            argType:(const char *)argType
              index:(NSInteger)index
                inv:(NSInvocation *)inv;
- (nullable id)getReturnValue:(const char *)returnType inv:(NSInvocation *)inv;
@end

NS_ASSUME_NONNULL_END
