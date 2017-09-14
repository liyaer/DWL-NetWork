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
#warning 这里不能用hasNet判断，原因是因为AF的网络监测结果还未回调。
//    if (self.hasNet)//可以将判断写在上面封装的Post、Get方法中，调用更加简洁；写在这里的好处可以对不同的接口做不同的处理
//    {
        [self PostRequestWithPath:url Params:nil Success:sucess Error:error];
//    }
//    else
//    {
//        DLog(@"没网的时候,本地存的是啥就按啥显示就可以！");
//    }
}

/*
 *                                              构造网络请求类的初衷
 
 *    寻求网络请求的最优操作，每次网络请求前进行网络连接是否正常的判断，有网进行请求，无网络不进行请求。将网络监测和接口请求封装在这一个类中，外界调用简单方便
 
 
 *                                                   注意事项
 
 *   1，【在App启动时】需要进行一些接口的请求（比如检查版本更新，检查是否过审核，自己服务器返回的一些标识等接口）：这类接口不能直接使用hasNet属性进行网络判断，因为有可能此时AF的网络监测结果回调还未执行，也就意味着hasNet并未被赋值，此时hasNet是不准确的。（可以参考上面的警告中的内容）
 
 *   2，【App启动后】需要进行一些接口的请求：可以直接使用hasNet属性
 
 *   3，~!~ 1中所说的一些在App启动时进行请求的这类接口，不一定都是写在【didFinishLaunchingWithOptions】方法里的才算，有时候写在MainVC中的也属于这类接口。
        ~!~ 本质上来说，这和接口在哪里请求的位置无关，而是和AF的网络监测结果的执行相对于接口的执行先后顺序有关，如果AF先回调了网络监测结果，然后执行了接口请求，那么此接口属于2中的那类接口，可以直接使用hasNet来判断，反之属于1中那类接口。
        ~!~ 所以1，2中所说的【在App启动时】和【App启动后】并不是绝对的，只是描述最一般的情况，具体使用时，不能只根据接口写的位置来判断是属于1还是2，需要根据其本质原理来进行调试区分
 
 *   4，由于每次网络改变AF都会回调网络监测结果，我们的getLaunchNetResult也会跟着调用多次，但是一般的接口我们只进行一次请求（过审核接口的除外），此时使用时有两种情况：
        ~!~ 有过审核的接口，【外界调用】这类接口时 ，除了过审核的接口用过审核标识判断是否跟随网络变化进行请求之外，其他接口都用dispatch_once来保证只执行一次
        ~!~ 没有过审核的接口，【直接在本类】的AF网络回调中，在getLaunchNetResult调用写在dispatch_once中，外界正常调用即可
 
 *   5，如果1中的这类接口过多，处理起来过于复杂，是在没有办法的时候，可以考虑放弃最优操作（放弃hasNet的判断）
 */




@end
