//
//  CTMediator.h
//  CTMediator
//
//  Created by casa on 16/3/13.
//  Copyright © 2016年 casa. All rights reserved.
//

#import <Foundation/Foundation.h>

/// 对返回的控制器的操作
typedef enum : NSUInteger {
    CTActionPush = 1,           // push 获得的控制器
    CTActionPresent,            // present 获得的控制器
    CTActionPushOrPresent,      // push或present 控制器，优先push
} CTAction;

extern NSString * _Nonnull const kCTMediatorParamsKeySwiftTargetModuleName;

@interface CTMediator : NSObject

/// 单例对象
+ (instancetype _Nonnull)sharedInstance;

/// 远程App调用接口
/// @param url url
/// @param completion 结束回调
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion;

/// 本地组件调用入口
/// @param targetName targetName
/// @param actionName actionName
/// @param params 参数
/// @param shouldCacheTarget 是否缓存target
- (id _Nullable )performTarget:(NSString * _Nullable)targetName action:(NSString * _Nullable)actionName params:(NSDictionary * _Nullable)params shouldCacheTarget:(BOOL)shouldCacheTarget;

/// 释放target缓存
/// @param fullTargetName 指定的target全称
- (void)releaseCachedTargetWithFullTargetName:(NSString * _Nullable)fullTargetName;

@end
  
// 简化调用单例的函数
CTMediator* _Nonnull CT(void);
