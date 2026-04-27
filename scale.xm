#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Hàm lấy Scale từ két sắt chung (Đã cập nhật Suite Name)
static CGFloat getGlobalScale() {
    float savedVal = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] floatForKey:@"GO_Scale"];
    
    // Nếu chưa chỉnh gì (bằng 0) thì lấy scale gốc của máy
    if (savedVal <= 0.1) {
        return [UIScreen mainScreen].scale;
    }
    return (CGFloat)savedVal;
}

// --- HOOK HỆ THỐNG HIỂN THỊ ---

%hook UIScreen
- (CGFloat)scale {
    return getGlobalScale();
}
- (CGFloat)nativeScale {
    return getGlobalScale();
}
%end

%hook UIWindow
- (void)setContentScaleFactor:(CGFloat)scale {
    %orig(getGlobalScale());
}
%end

%hook UIView
- (void)setContentScaleFactor:(CGFloat)scale {
    %orig(getGlobalScale());
}
%end

// --- HOOK ĐỒ HỌA NẶNG (METAL & OPENGL) ---

%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale {
    %orig(getGlobalScale());
}
%end

%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale {
    %orig(getGlobalScale());
}
%end
