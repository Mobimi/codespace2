#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

%hook CAMetalLayer
- (NSUInteger)maximumDrawableCount {
    // Mở két sắt kiểm tra xem công tắc Input Lag có bật không
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_InputLag"];
    
    if (isEnabled) {
        // Mặc định của iOS thường là 3. Ép xuống 2 để GPU xuất hình ra màn hình nhanh hơn, giảm độ trễ cảm ứng.
        return 2; 
    }
    
    // Nếu công tắc TẮT, trả về thông số zin của hệ thống/game
    return %orig; 
}
%end
