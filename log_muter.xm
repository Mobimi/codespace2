#import <Foundation/Foundation.h>
#import <substrate.h>

// Khai báo con trỏ giữ hàm gốc
static void (*orig_NSLogv)(NSString *format, va_list args);

// Hàm Hook thay thế
static void hook_NSLogv(NSString *format, va_list args) {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_LogMuter"];
    
    if (isEnabled) {
        // Nếu bật: Ngậm miệng lại, không làm gì cả, kết thúc luôn!
        return; 
    }
    
    // Nếu tắt: Gọi lại hàm gốc để in log bình thường
    orig_NSLogv(format, args);
}

// Bắt đầu tiêm lúc khởi chạy
%ctor {
    // Hook hàm NSLogv của hệ thống
    MSHookFunction((void *)NSLogv, (void *)hook_NSLogv, (void **)&orig_NSLogv);
}
