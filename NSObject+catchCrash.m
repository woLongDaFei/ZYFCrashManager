//
//  NSObject+catchCrash.m
//  学习
//
//  Created by 老玩童－赵永斐 on 2020/7/16.
//  Copyright © 2020年 赵永斐. All rights reserved.
//

#import "NSObject+catchCrash.h"
#import <objc/runtime.h>


#pragma mark - GLUnrecognizedSelector
@interface __GLUnrecognizedSelectorHandler : NSObject

@end

@implementation __GLUnrecognizedSelectorHandler

id __unrecognizedSelectorHandler_func(id self, SEL _cmd) {
    return nil;
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    class_addMethod(self.class, sel, (IMP)__unrecognizedSelectorHandler_func, "@@:");
    [super resolveInstanceMethod:sel];
    return YES;
}

@end


@implementation NSObject (catchCrash)
static __GLUnrecognizedSelectorHandler *_unrecognizedSelectorHandler = nil;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _unrecognizedSelectorHandler = [[__GLUnrecognizedSelectorHandler alloc] init];
        [self swizzleInstanceSEL:@selector(forwardingTargetForSelector:)
                         withSEL:@selector(gl_forwardingTargetForSelector:) forClass:[self class]];
    });
}


- (id)gl_forwardingTargetForSelector:(SEL)aSelector {
    
    // 在forwardingTargetForSelector:被重写或者被其它SDK Hook时,
    // 如果返回了target，优先使用Hook前的方法返回值
    id target = [self gl_forwardingTargetForSelector:aSelector];
    if ((target || [self subclassOverideForwardingMethods]) && ![[NSNull null] isEqual:self]) {
        return target;
    }
    
    return _unrecognizedSelectorHandler;
}


//判断类是否重写了forwardInvocation方法的话，就不应该对forwardingTargetForSelector进行重写了，否则会影响到该类型的对象原本的消息转发流程。
- (BOOL)subclassOverideForwardingMethods {
    BOOL overided = NO;
    
    overided = (class_getMethodImplementation([NSObject class], @selector(forwardInvocation:)) != class_getMethodImplementation([self class], @selector(forwardInvocation:))) ||
    (class_getMethodImplementation([NSObject class], @selector(forwardingTargetForSelector:)) != class_getMethodImplementation([self class], @selector(forwardingTargetForSelector:)));
    
    return overided;
}


+ (void)swizzleInstanceSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL forClass:(Class)cls {
    
    Method originalMethod = class_getInstanceMethod(cls, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSEL);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
    
}
@end
