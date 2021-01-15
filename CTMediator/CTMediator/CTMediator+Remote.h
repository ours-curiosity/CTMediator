//
//  CTMediator+Remote.h
//  CTMediator
//
//  Created by walker on 2021/1/15.
//  Copyright © 2021 casa. All rights reserved.
//

#import "CTMediator.h"
#import "CTMediator+HandyTools.h"
NS_ASSUME_NONNULL_BEGIN

/// 此类目用来帮助开发远程调用的功能， 并添加快捷跳转的方法
@interface CTMediator (Remote)

/// 远程App调用入口
/// @param url url
/// @param params 参数
/// @param completion 结束回调
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url params:(NSDictionary *_Nullable)params completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion;

/// 远程App调用入口
/// @param url url
/// @param params 参数
/// @param action 返回值如果是控制器所做的操作(如果返回值不是UIViewController，忽略此参数)
/// @param animated 操作控制器时是否启用动画
/// @param completion 结束回调
- (id _Nullable)performActionWithUrl:(NSURL * _Nullable)url params:(NSDictionary *_Nullable)params action:(CTAction)action actionAnimated:(BOOL)animated completion:(void(^_Nullable)(NSDictionary * _Nullable info))completion;

/// 本地组件调用入口
/// @param targetName targetName
/// @param actionName actionName
/// @param params 参数
/// @param action 如果返回值是控制器，采取的操作枚举
/// @param animated 操作控制器时是否启动动画
/// @param shouldCacheTarget 是否缓存target
- (id _Nullable )performTarget:(NSString * _Nullable)targetName action:(NSString * _Nullable)actionName params:(NSDictionary * _Nullable)params actionType:(CTAction)actionType actionAnimated:(BOOL)animated shouldCacheTarget:(BOOL)shouldCacheTarget;
@end

NS_ASSUME_NONNULL_END
