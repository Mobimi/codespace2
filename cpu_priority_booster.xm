#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

%hook UIWindowScene
- (void)_readySceneForConnection {
    // Bắt buộc phải gọi %orig để App/Game khởi tạo UI bình thường, không là đen màn hình
    %orig; 
    
    // Mở két sắt xem công tắc có bật không
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_CPUPriority"];
    
    if (isEnabled) {
        // Lấy luồng chạy chính của game
        NSThread *mainThread = [NSThread mainThread];
        
        // Ép lên mức độ ưu tiên cao nhất (User Interactive)
        if ([mainThread respondsToSelector:@selector(setQualityOfService:)]) {
            [mainThread setQualityOfService:NSQualityOfServiceUserInteractive];
        }
        
        // Set quyền tranh giành CPU tuyệt đối (1.0 là max)
        [mainThread setThreadPriority:1.0];
    }
}
%end
