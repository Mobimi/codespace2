#import <Foundation/Foundation.h>

%hook NSProcessInfo
- (NSProcessInfoThermalState)thermalState {
    // Mở két sắt xem công tắc Anti-Throttling có bật không
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_ThermalBypass"];
    
    if (isEnabled) {
        // Nếu BẬT: Báo cáo với iOS là nhiệt độ máy đang ở trạng thái "Nominal" (Lý tưởng/Bình thường)
        return NSProcessInfoThermalStateNominal;
    }
    
    // Nếu TẮT: Trả về trạng thái nhiệt độ thực tế của máy
    return %orig;
}
%end
