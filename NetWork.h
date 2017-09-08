//
//  checkNet.h
//  WeChatMaker
//
//  Created by 杜文亮 on 2017/9/6.
//  Copyright © 2017年 CompanyName（公司名）. All rights reserved.
//


#pragma mark - 引用头文件

#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "AFNetworking.h"




#pragma mark - 声明block
/*
 *   网络监测
 */
typedef void (^getLaunchNetResult)();
/*
 *   接口
 */
typedef void (^SuccessBlock)(id requestEncode);
typedef void (^ErrorBlock)(NSError *error);




#pragma mark - 类的声明

@interface NetWork : NSObject<NSCopying,NSMutableCopying>

/*
 *   指定初始化方法
 */
+(instancetype)instance;

//=================================网络监测========================================================

/*
 *   每次启动时，在AppDelegate中先开启了网络监测，然后执行了检查是否有新版的代码。但是由于网络监测的block回调慢于检查更新代码的执行，导致在执行检查更新的时候，hasNet还未被赋值，此时是默认值NO(导致即使是联网状态下hasNet为NO)
 *   为了解决上述问题，设置一个block，在网络监测完成时（hasNet已经被赋值），再执行检查新版本这部分代码
 */
@property (nonatomic,copy) getLaunchNetResult getLaunchNetResult;

/*
 *   当前是否有网络链接
 */
@property (nonatomic,assign) BOOL hasNet;

/*
 *   说明：1，2为实时监测，监测结果用hasNet存储，可以及时根据网络状态做出响应；
 *        3仅仅是一个判断当前网络的方法，无法实时监测
 */

/*
 *   1 - 苹果自带的Reachability检测网络状态(封装的这个通知会调用多次，不知为何？)
 */
@property (nonatomic,strong) Reachability *reachability;

/*
 *   2 - AFNetworkReachabilityManager（最省事，一般都是用AF进行网络请求，到时候检测网络的方法直接写到网络请求类里面即可）
 */
@property (nonatomic,strong) AFNetworkReachabilityManager *manger;

/*
 *   3 - 根据当前状态栏的显示判断网络状态（当然，此方法存在一定的局限性，比如当状态栏被隐藏的时候，无法使用此方法）
 */
-(NSString *)statusBarShowNet;


//==============================接口==============================================================

/*
 *   检查是否有新版本
 */
-(void)PostGetAppInfo:(NSString *)url sucess:(SuccessBlock) sucess Error:(ErrorBlock) error;


@end
