#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <pthread.h>
#include <mach/mach.h>
#include <mach/thread_policy.h>

// ═══════════════════════════════════════════════
//   CPU OPTIMIZER — Thread & Queue Level
//   Bổ sung cho cpu_priority_booster.xm:
//   Booster lo main thread 1 lần,
//   file này lo TẤT CẢ thread mới + GCD queues
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL cpuOptEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_CPUOpt"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_CPUOpt"];
        }];
    });
    return cached;
}

// ── NSTHREAD: Boost mọi thread khi start ─────
%hook NSThread

- (void)start {
    %orig;
    if (!cpuOptEnabled()) return;
    if (self.isMainThread) return; // Main thread đã do booster.xm lo

    // Set threadPriority trực tiếp (API public, hoạt động đúng)
    self.threadPriority = 1.0;
}

// Hook initWithBlock để boost QoS ngay khi thread chạy
- (instancetype)initWithBlock:(void (^)(void))block {
    if (!cpuOptEnabled()) return %orig;

    void (^boostedBlock)(void) = ^{
        if (![[NSThread currentThread] isMainThread]) {
            pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
        }
        if (block) block();
    };
    return %orig(boostedBlock);
}

%end

// ── NSOPERATIONQUEUE: Boost queue GCD ────────
%hook NSOperationQueue

// Không cho queue xuống dưới UserInitiated
- (void)setQualityOfService:(NSQualityOfService)qualityOfService {
    if (cpuOptEnabled()) {
        if (qualityOfService > NSQualityOfServiceUserInitiated) {
            qualityOfService = NSQualityOfServiceUserInitiated;
        }
    }
    %orig(qualityOfService);
}

// Tối thiểu 4 concurrent ops để tận dụng A14 6-core
- (void)setMaxConcurrentOperationCount:(NSInteger)count {
    if (cpuOptEnabled() && count > 0 && count < 4) {
        count = 4;
    }
    %orig(count);
}

%end
