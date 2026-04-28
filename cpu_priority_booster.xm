#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <pthread.h>

// Hook vào UIApplication thay vì UIWindowScene để né xung đột với GUI.x
%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig; 
    
    // Chỉ kích hoạt 1 lần duy nhất khi game mở lên
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // Mở két sắt chung xem công tắc có bật không
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
        BOOL isEnabled = [defaults boolForKey:@"GO_CPUPriority"];
        
        if (isEnabled) {
            // Đẩy lệnh này vào luồng chính để buff sức mạnh
            dispatch_async(dispatch_get_main_queue(), ^{
                // Ép lên mức độ ưu tiên cao nhất (User Interactive)
                pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
                
                // Set quyền tranh giành CPU tuyệt đối (1.0 là max)
                [NSThread setThreadPriority:1.0];
            });
        }
    });
}
%end
