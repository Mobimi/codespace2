#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <pthread.h>

%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
        BOOL isEnabled = [defaults boolForKey:@"GO_CPUPriority"];

        if (isEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
                [NSThread setThreadPriority:1.0];
            });
        }
    });
}
%end
