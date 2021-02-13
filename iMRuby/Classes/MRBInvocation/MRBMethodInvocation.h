//
//  MRBMethodInvocation.h
//  iMRuby
//
//  Created by ping.cao on 2021/2/13.
//

#import "MRBInvocation.h"

NS_ASSUME_NONNULL_BEGIN

@interface MRBMethodInvocation : MRBInvocation

@property (nonatomic, assign) SEL selector;

@end

NS_ASSUME_NONNULL_END
