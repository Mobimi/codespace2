#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook UIApplication

// Hook hàm cảnh báo RAM số 1
- (void)didReceiveMemoryWarning {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_RAMBypass"];
    
    // Nếu công tắc TẮT, cho phép iOS gửi cảnh báo bình thường
    if (!isEnabled) {
        %orig;
    }
    // Nếu BẬT, âm thầm bỏ qua (không gọi %orig), game sẽ không biết máy đang hết RAM
}

// Hook hàm cảnh báo RAM số 2 (hàm ẩn của hệ thống)
- (void)_performMemoryWarning {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_RAMBypass"];
    
    if (!isEnabled) {
        %orig;
    }
}

%end
