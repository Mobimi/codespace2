#import <UIKit/UIKit.h>

%hook UIVisualEffectView
// Hook vào class chuyên tạo hiệu ứng mờ của Apple
- (void)setEffect:(UIVisualEffect *)effect {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_AntiBlur"];
    if (isEnabled) {
        // Tắt lớp mờ (trả về nền trong suốt hoặc đen/trắng cơ bản) -> GPU không phải render nội suy nữa
        %orig(nil); 
    } else {
        %orig(effect);
    }
}
%end
