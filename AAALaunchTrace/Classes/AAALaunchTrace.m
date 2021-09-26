//
//  TBSLaunchTrace.m
//  testLaunch
//
//  Created by penghua fu on 2021/8/23.
//

#import "AAALaunchTrace.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/mach.h>

/**    App Launch  各个阶段
                                          finishLaunching结束
                                 finishLaunching开始  |       首页渲染完成
 进程创建                    第一个+load     main开始         |                     |          launch结束
   |                                      |                      |                |                     |                  |
   |                                      |                      |                |                     |                  |
   |                                      |                      |                |                     |                  |
   ----->Process Start----->Premain----->Main----->LiftCycle----->homePage
 
 1. 将APP Launch分为五个阶段，以进程创建时间为launch起点
 2. 第一个+load方法执行标记为Premain的起点
 3. main函数开始时间
 4. AppDelegate生命周期，以FinishLaunching记，主要统计SDK初始化耗时
 5. 首页渲染时间
 启动完成
 */

@interface AAALaunchTrace ()

@property (nonatomic, strong) NSMutableDictionary *launchInfo;

@end

@implementation AAALaunchTrace

+ (void)load {
    [self firstLoad];
}

void static __attribute__((constructor)) before_main() {
    [[AAALaunchTrace shared] mainStart];
}

+ (instancetype)shared {
    static AAALaunchTrace *_share = nil;
    static dispatch_once_t once_token;
    dispatch_once(&once_token, ^{
        _share = [[AAALaunchTrace alloc] init];
        [_share addNotification];
    });
    return _share;
}

- (NSMutableDictionary *)launchInfo {
    if (!_launchInfo) {
        _launchInfo = [NSMutableDictionary dictionary];
    }
    return _launchInfo;
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishLaunching) name:UIApplicationDidFinishLaunchingNotification object:nil];
}

- (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

- (UInt64)processStartTime {
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        return kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * 1000.0 + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec / 1000.0;
    } else {
        NSAssert(NO, @"无法取得进程的信息");
        return 0;
    }
}

- (UInt64)currentTime {
    NSDate *date = [NSDate date];
    NSTimeInterval interval = [date timeIntervalSince1970];
    return interval * 1000;
}

#pragma mark ---  各阶段时间记录

- (void)launchStart {
    UInt64 launchStart = [self processStartTime];
    self.launchInfo[@"launchStart"] = @(launchStart);
}

/// 第一个+load方法执行
+ (void)firstLoad {
    AAALaunchTrace *shared = [AAALaunchTrace shared];
    [shared launchStart];
    UInt64 firstLoad = [shared currentTime];
    shared.launchInfo[@"firstLoad"] = @(firstLoad);
}

/// app main函数开始执行
- (void)mainStart {
    UInt64 mainStart = [self currentTime];
    self.launchInfo[@"mainStart"] = @(mainStart);
}

/// finishLaunching开始执行
- (void)didLaunchingStart {
    
}

/// finishLaunching完成
- (void)didFinishLaunching {
    UInt64 finishLaunching = [self currentTime];
    self.launchInfo[@"didFinishLaunching"] = @(finishLaunching);
}

/// app启动完成
+ (void)launchEnd {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AAALaunchTrace *shared = [AAALaunchTrace shared];
        UInt64 launchEnd = [shared currentTime];
        shared.launchInfo[@"launchEnd"] = @(launchEnd);
    });
}

+ (NSDictionary *)launchTraceInfo {
    return [AAALaunchTrace shared].launchInfo;
}
@end
