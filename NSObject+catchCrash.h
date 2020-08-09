//
//  NSObject+catchCrash.h
//  学习
//
//  Created by 老玩童－赵永斐 on 2020/7/16.
//  Copyright © 2020年 赵永斐. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (catchCrash)

+ (void)swizzleInstanceSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL forClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
