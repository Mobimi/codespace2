#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <pthread.h>

// Hook vào UIApplication thay vì UIWindowScene để né xung đột với GUI.x
%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;

    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
    if (![defaults boolForKey:@"GO_CPUPriority"]) return;

    // Delay 0.3s để UIKit restore xong view hierarchy sau khi foreground
    // tránh priority inversion với các internal UIKit lock
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
        [NSThread setThreadPriority:1.0];
    });
}
%end