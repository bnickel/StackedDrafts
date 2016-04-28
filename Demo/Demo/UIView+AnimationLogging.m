//
//  UIView+AnimationLogging.m
//  Demo
//
//  Created by Brian Nickel on 4/26/16.
//  Copyright © 2016 Stack Exchange. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

volatile BOOL SEViewLogAnimations = NO;

@implementation UIView (AnimationLogging)

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(object_getClass(self), @selector(animateWithDuration:delay:options:animations:completion:)),
                                   class_getInstanceMethod(object_getClass(self), @selector(SE_animateWithDuration:delay:options:animations:completion:)));
    method_exchangeImplementations(class_getInstanceMethod(object_getClass(self), @selector(animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)),
                                   class_getInstanceMethod(object_getClass(self), @selector(SE_animateWithDuration:delay:usingSpringWithDamping:initialSpringVelocity:options:animations:completion:)));
    
    Method original = class_getInstanceMethod(self, @selector(viewForBaselineLayout));
    class_addMethod(self, @selector(viewForFirstBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
    class_addMethod(self, @selector(viewForLastBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
}

+ (void)SE_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    if (SEViewLogAnimations) {
        NSLog(@"Animating with duration: %f, delay: %f, options: %llx, completion: %@", duration, delay, (long long)options, completion != nil ? @"YES" : @"NO");
    }
    [self SE_animateWithDuration:duration delay:delay options:options animations:animations completion:completion];
}

+ (void)SE_animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay usingSpringWithDamping:(CGFloat)dampingRatio initialSpringVelocity:(CGFloat)velocity options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL))completion
{
    if (SEViewLogAnimations) {
        NSLog(@"Animating with duration: %f, delay: %f, damping: %f, velocity: %f, options: %llx, completion: %@", duration, delay, dampingRatio, velocity, (long long)options, completion != nil ? @"YES" : @"NO");
    }
    [self SE_animateWithDuration:duration delay:delay usingSpringWithDamping:dampingRatio initialSpringVelocity:velocity options:options animations:animations completion:completion];
}

@end

#ifdef DEBUG

// http://stackoverflow.com/a/36926620/860000

@implementation UIView (FixViewDebugging)

+ (void)load
{
    Method original = class_getInstanceMethod(self, @selector(viewForBaselineLayout));
    class_addMethod(self, @selector(viewForFirstBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
    class_addMethod(self, @selector(viewForLastBaselineLayout), method_getImplementation(original), method_getTypeEncoding(original));
}

@end

#endif
