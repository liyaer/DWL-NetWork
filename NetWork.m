//
//  checkNet.m
//  WeChatMaker
//
//  Created by 杜文亮 on 2017/9/6.
//  Copyright © 2017年 CompanyName（公司名）. All rights reserved.
//



#import "NetWork.h"


#pragma mark - 静态变量的声明

static NetWork *_instance;




#pragma mark - 类的实现

@implementation NetWork

#pragma mark - 指定初始化方法

+(instancetype)instance
{
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    
    // 由于alloc方法内部会调用allocWithZone: 所以我们只需要保证在该方法只创建一个对象即可
    dispatch_once(&onceToken,^{
        
        // 只执行1次的代码(这里面默认是线程安全的)
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone
{
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
    return _instance;
}




#pragma mark - 苹果自带的Reachability检测网络状态

-(Reachability *)reachability
{
    if (!_reachability)
    {
        // 监听网络状态改变的通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStateChange) name:kReachabilityChangedNotification object:nil];
        
        _reachability = [Reachability reachabilityWithHostName:@"www.baidu.com"];
    }
    return _reachability;
}
/*
 *   收到网络改变时的通知方法
 */
-(void)networkStateChange
{
    switch([self.reachability currentReachabilityStatus])
    {
        case NotReachable:
        {
            DLog(@"=========================meiwang");
            [TipView showHUD:@"你的网络飞走了~" showTime:2.0];
            self.hasNet = NO;
        }
            break;
        case ReachableViaWWAN:
        {
            DLog(@"GGGGGG");
            self.hasNet = YES;
        }
            break;
        case ReachableViaWiFi:
        {
            DLog(@"===========================WIFI");
            self.hasNet = YES;
        }
            break;
    }
}
/*
 *   移除监听
 */
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
}




#pragma mark - AFNetworkReachabilityManager

- (AFNetworkReachabilityManager *)manger
{
    if (!_manger)
    {
        // 1.获得网络监控的管理者
        _manger = [AFNetworkReachabilityManager sharedManager];
        // 2.设置网络状态改变后的处理
        __weak typeof(self) weakSelf = self;
        // 当网络状态改变了, 就会调用这个block
        [_manger setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
         {
             switch (status)
             {
                 case AFNetworkReachabilityStatusUnknown: // 未知网络
                     NSLog(@"未知网络");
                     break;
                 case AFNetworkReachabilityStatusNotReachable: // 没有网络(断网)
                 {
                     DLog(@"meiwang");
                     [TipView showHUD:@"你的网络飞走了~" showTime:2.0];
                     weakSelf.hasNet = NO;
                 }
                     break;
                 case AFNetworkReachabilityStatusReachableViaWWAN: // 手机自带网络
                 {
                     DLog(@"GGGGGG");
                     weakSelf.hasNet = YES;
                 }
                     break;
                 case AFNetworkReachabilityStatusReachableViaWiFi: // WIFI
                 {
                     DLog(@"WIFI");
                     weakSelf.hasNet = YES;
                 }
                     break;
             }
             
             //在网络监测完成时（hasNet已经被赋值），再执行检查新版本这部分代码
             if (weakSelf.getLaunchNetResult)
             {
                 weakSelf.getLaunchNetResult();
             }
         }];
    }
    return _manger;
}




#pragma mark - 根据当前状态栏的显示判断网络状态（当然，此方法存在一定的局限性，比如当状态栏被隐藏的时候，无法使用此方法）

-(NSString *)statusBarShowNet
{
    // 状态栏是由当前app控制的，首先获取当前app
    UIApplication *app = [UIApplication sharedApplication];
    
    NSArray *children = [[[app valueForKeyPath:@"statusBar"] valueForKeyPath:@"foregroundView"] subviews];
    
    int type = 0;
    for (id child in children)
    {
        if ([child isKindOfClass:NSClassFromString(@"UIStatusBarDataNetworkItemView")])
        {
            type = [[child valueForKeyPath:@"dataNetworkType"] intValue];
        }
    }
    switch (type)
    {
        case 1: return @"2G";
            break;
            
        case 2: return @"3G";
            break;
            
        case 3: return @"4G";
            break;
            
        case 5: return @"WIFI";
            break;
            
        default: return @"NO-WIFI";//代表未知网络
            break;
    }
}




#pragma mark - 接口

//AFNetWorking 3.x版本  适配HTTPS请求 （根据需要确定是否开启HTTPS）
-(AFSecurityPolicy *)setSecurityPolicy
{
    //获取本地证书
    NSString * cerPath = [[NSBundle mainBundle] pathForResource:@"zz.oricg.com" ofType:@"cer"];
    NSData * cerData = [NSData dataWithContentsOfFile:cerPath];
    //设置证书模式(AFSSLPinningModeCertificate证书认证模式，抓包无法抓取到；需要抓包测试的话，更改认证模式即可)
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate withPinnedCertificates:[[NSSet alloc] initWithObjects:cerData, nil]];
    //客户端是否信任非法证书
    securityPolicy.allowInvalidCertificates = YES;
    //是否在证书域字段中验证域名
    [securityPolicy setValidatesDomainName:NO];
    
    return securityPolicy;
}

//对Post方式请求的接口提供一个便利调用的封装
-(void)PostRequestWithPath:(NSString *)url Params:(id)dict Success:(SuccessBlock)DSuccess Error:(ErrorBlock)DError
{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
//    session.securityPolicy = [self setSecurityPolicy];（根据需要确定是否开启HTTPS）
    [session POST:url parameters:dict progress:^(NSProgress * _Nonnull uploadProgress)
    {
        
    }
    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        DLog(@"请求成功！");
        DSuccess(responseObject);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        DLog(@"请求失败！-> %@",error);
        DError(error);
    }];
}

//对Get方式请求的接口提供一个便利调用的封装
-(void)GetRequestWithPath:(NSString *)url Params:(id)dict Success:(SuccessBlock)DSuccess Error:(ErrorBlock)DError
{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
//    session.securityPolicy = [self setSecurityPolicy];（根据需要确定是否开启HTTPS）
    
//    [session.requestSerializer willChangeValueForKey:@"timeoutInterval"];
//    session.requestSerializer.timeoutInterval = 15.0;
//    [session.requestSerializer didChangeValueForKey:@"timeoutInterval"];
//    session.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript",@"text/html",@"text/plain",@"text/xml",@"image/gif", nil];
    
    [session GET:url parameters:dict progress:^(NSProgress * _Nonnull downloadProgress)
    {
        
    }
    success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject)
    {
        DLog(@"请求成功！");
        DSuccess(responseObject);
    }
    failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error)
    {
        DLog(@"请求失败！-> %@",error);
        DError(error);
    }];
}

/*
 *   检查是否有新版本
 */
-(void)PostGetAppInfo:(NSString *)url sucess:(SuccessBlock) sucess Error:(ErrorBlock) error
{
    if (self.hasNet)//可以将判断写在上面封装的Post、Get方法中，调用更加简洁；写在这里的好处可以对不同的接口做不同的处理
    {
        [self PostRequestWithPath:url Params:nil Success:sucess Error:error];
    }
    else
    {
        DLog(@"没网的时候,本地存的是啥就按啥显示就可以！");
    }
}


@end
