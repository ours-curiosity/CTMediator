//
//  CTMediator+Remote.m
//  CTMediator
//
//  Created by walker on 2021/1/15.
//  Copyright © 2021 casa. All rights reserved.
//

#import "CTMediator+Remote.h"
#import "CTMediator+HandyTools.h"
#import <objc/message.h>
@implementation CTMediator (Remote)

/// 远程App调用入口
/// @param url url
/// @param params 参数
/// @param completion 结束回调
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url params:(NSDictionary *_Nullable)params completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion {
    
    if (url == nil) {
        return nil;
    }
    
    NSMutableDictionary *allParams = [[NSMutableDictionary alloc] init];
    NSString *urlString = [url query];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [allParams setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    // 合并传入的参数
    if (params != nil && params.count > 1) {
        [allParams addEntriesFromDictionary:params];
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    return result;
}

/// 远程App调用入口
/// @param url url
/// @param params 参数
/// @param action 返回值如果是控制器所做的操作(如果返回值不是UIViewController，忽略此参数)
/// @param animated 操作控制器时是否启用动画
/// @param completion 结束回调
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url params:(NSDictionary *_Nullable)params action:(CTAction)action actionAnimated:(BOOL)animated completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion {
    
    if (url == nil) {
        return nil;
    }
    
    NSMutableDictionary *allParams = [[NSMutableDictionary alloc] init];
    NSString *urlString = [url query];
    for (NSString *param in [urlString componentsSeparatedByString:@"&"]) {
        NSArray *elts = [param componentsSeparatedByString:@"="];
        if([elts count] < 2) continue;
        [allParams setObject:[elts lastObject] forKey:[elts firstObject]];
    }
    // 合并传入的参数
    if (params != nil && params.count > 1) {
        [allParams addEntriesFromDictionary:params];
    }
    
    // 这里这么写主要是出于安全考虑，防止黑客通过远程方式调用本地模块。这里的做法足以应对绝大多数场景，如果要求更加严苛，也可以做更加复杂的安全逻辑。
    NSString *actionName = [url.path stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([actionName hasPrefix:@"native"]) {
        return @(NO);
    }
    
    // 这个demo针对URL的路由处理非常简单，就只是取对应的target名字和method名字，但这已经足以应对绝大部份需求。如果需要拓展，可以在这个方法调用之前加入完整的路由逻辑
    id result = [self performTarget:url.host action:actionName params:params shouldCacheTarget:NO];
    if (completion) {
        if (result) {
            completion(@{@"result":result});
        } else {
            completion(nil);
        }
    }
    
    // 如果返回值是控制器，就按枚举操作
    if ([result isKindOfClass:NSClassFromString(@"UIViewController")]) {
        switch (action) {
            case CTActionPush:
                [self pushViewController:result animated:animated];
                break;
            case CTActionPresent:
                [self presentViewController:result animated:animated completion:nil];
                break;
            case CTActionPushOrPresent:
                if (![self pushViewController:result animated:animated]) {
                    [self presentViewController:result animated:animated completion:nil];
                }
                break;
            default:
                break;
        }
    }
    return result;
}


/// 本地组件调用入口
/// @param targetName targetName
/// @param actionName actionName
/// @param params 参数
/// @param action 如果返回值是控制器，采取的操作枚举
/// @param animated 操作控制器时是否启动动画
/// @param shouldCacheTarget 是否缓存target
- (id _Nullable )performTarget:(NSString * _Nullable)targetName action:(NSString * _Nullable)actionName params:(NSDictionary * _Nullable)params actionType:(CTAction)actionType actionAnimated:(BOOL)animated shouldCacheTarget:(BOOL)shouldCacheTarget {
    if (targetName == nil || actionName == nil) {
        return nil;
    }
    
    NSString *swiftModuleName = params[kCTMediatorParamsKeySwiftTargetModuleName];
    
    // generate target
    NSString *targetClassString = nil;
    if (swiftModuleName.length > 0) {
        targetClassString = [NSString stringWithFormat:@"%@.Target_%@", swiftModuleName, targetName];
    } else {
        targetClassString = [NSString stringWithFormat:@"Target_%@", targetName];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    NSObject *target = [self performSelector:@selector(safeFetchCachedTarget:) withObject:targetClassString];
    if (target == nil) {
        Class targetClass = NSClassFromString(targetClassString);
        target = [[targetClass alloc] init];
    }
    
    // generate action
    NSString *actionString = [NSString stringWithFormat:@"Action_%@:", actionName];
    SEL action = NSSelectorFromString(actionString);
    
    if (target == nil) {
        // 这里是处理无响应请求的地方之一，这个demo做得比较简单，如果没有可以响应的target，就直接return了。实际开发过程中是可以事先给一个固定的target专门用于在这个时候顶上，然后处理这种请求的
        ((void (*)(id, SEL, NSString *, NSString *, NSDictionary *))objc_msgSend)(self, @selector(NoTargetActionResponseWithTargetString:selectorString:originParams:), targetClassString, actionString, params);
        return nil;
    }
    
    if (shouldCacheTarget) {
        ((void(*)(id, SEL, NSObject *, NSString *))objc_msgSend)(self, @selector(safeSetCachedTarget:key:), target, targetClassString);
    }
    
    id result = nil;
    
    if ([target respondsToSelector:action]) {
        result = ((id (*)(id, SEL, SEL, NSObject *, NSDictionary *))objc_msgSend)(self, @selector(safePerformAction:target:params:), action, target, params);
    } else {
        // 这里是处理无响应请求的地方，如果无响应，则尝试调用对应target的notFound方法统一处理
        SEL action = NSSelectorFromString(@"notFound:");
        if ([target respondsToSelector:action]) {
            result = ((id (*)(id, SEL, SEL, NSObject *, NSDictionary *))objc_msgSend)(self, @selector(safePerformAction:target:params:), action, target, params);
        } else {
            // 这里也是处理无响应请求的地方，在notFound都没有的时候，这个demo是直接return了。实际开发过程中，可以用前面提到的固定的target顶上的。
            ((void (*)(id, SEL, NSString *, NSString *, NSDictionary *))objc_msgSend)(self, @selector(NoTargetActionResponseWithTargetString:selectorString:originParams:), targetClassString, actionString, params);
#pragma clang diagnostic pop
            @synchronized (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [[self performSelector:NSSelectorFromString(@"cachedTarget")] performSelector:NSSelectorFromString(@"removeObjectForKey") withObject:targetClassString];
#pragma clang diagnostic pop
            }
            return nil;
        }
    }
    
    // 如果返回值是控制器，就按枚举操作
    if ([result isKindOfClass:NSClassFromString(@"UIViewController")]) {
        switch (actionType) {
            case CTActionPush:
                [self pushViewController:result animated:animated];
                break;
            case CTActionPresent:
                [self presentViewController:result animated:animated completion:nil];
                break;
            case CTActionPushOrPresent:
                if (![self pushViewController:result animated:animated]) {
                    [self presentViewController:result animated:animated completion:nil];
                }
                break;
            default:
                break;
        }
    }
    
    return result;
}

@end
