#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <pthread.h>

%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
    BOOL isEnabled = [defaults boolForKey:@"GO_CPUPriority"];
    if (!isEnabled) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
        [NSThread setThreadPriority:1.0];
    });
}
%end
