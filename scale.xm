#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Hàm tính toán tỉ lệ dựa trên hệ số %
static CGFloat getScaledValue(CGFloat origScale) {
    float multiplier = [[NSUserDefaults standardUserDefaults] floatForKey:@"GO_Scale"];
    
    // Nếu chưa nhập gì hoặc nhập 0, mặc định là 1.0 (100% gốc)
    if (multiplier <= 0.01) return origScale;
    
    // Giới hạn an toàn: Không cho giảm dưới 0.2 (tránh màn hình đen/mờ quá mức)
    if (multiplier < 0.2) multiplier = 0.2;
    
    // Trả về: Giá trị gốc của máy * Hệ số bác nhập
    return origScale * multiplier;
}

%hook UIScreen
- (CGFloat)scale { return getScaledValue(%orig); }
- (CGFloat)nativeScale { return getScaledValue(%orig); }
%end

%hook UIWindow
- (void)setContentScaleFactor:(CGFloat)scale { %orig(getScaledValue(scale)); }
%end

%hook UIView
- (void)setContentScaleFactor:(CGFloat)scale { %orig(getScaledValue(scale)); }
%end

%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale { %orig(getScaledValue(scale)); }
%end

%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale { %orig(getScaledValue(scale)); }
%end
