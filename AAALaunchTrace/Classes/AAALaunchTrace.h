//
//  TBSLaunchTrace.h
//  testLaunch
//
//  Created by penghua fu on 2021/8/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AAALaunchTrace : NSObject

/// app启动完成
+ (void)launchEnd;

+ (NSDictionary *)launchTraceInfo;

@end

NS_ASSUME_NONNULL_END
