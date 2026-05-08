#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Cache vào RAM, chỉ đọc disk 1 lần duy nhất
static CGFloat cachedScale = -1.0;

static CGFloat getGlobalScale() {
    if (cachedScale == -1.0) {
        float saved = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                       floatForKey:@"GO_Scale"];
        // FIX: Phải validate scale hợp lệ trước khi dùng
        // saved == 0.0 nghĩa là chưa set bao giờ → trả về 0.0 để báo "dùng giá trị gốc"
        cachedScale = (saved >= 0.5f && saved <= 3.0f) ? (CGFloat)saved : 0.0;
    }
    return cachedScale;
}

// Gọi hàm này khi user bấm Apply trong menu
void updateGlobalScale(CGFloat newScale) {
    // Clamp để đảm bảo không bao giờ set giá trị vô nghĩa
    if (newScale < 0.5f) newScale = 0.5f;
    if (newScale > 3.0f) newScale = 3.0f;
    cachedScale = newScale;
    [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
     setFloat:(float)newScale forKey:@"GO_Scale"];
}

%hook UIScreen
- (CGFloat)scale {
    CGFloat s = getGlobalScale();
    // FIX: Chỉ override khi có giá trị hợp lệ thực sự
    return (s > 0.0) ? s : %orig;
}
- (CGFloat)nativeScale {
    CGFloat s = getGlobalScale();
    return (s > 0.0) ? s : %orig;
}
%end

// FIX: Không hook UIWindow và UIView setContentScaleFactor nữa
// Lý do: truyền scale sai (kể cả 0.0) vào toàn bộ UIView sẽ crash
// khi Metal/CA cố tạo drawable với kích thước = 0 trên iOS 18
// Chỉ hook CAMetalLayer và CAEAGLLayer là đủ và an toàn hơn nhiều

%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale {
    CGFloat s = getGlobalScale();
    %orig(s > 0.0 ? s : scale);
}
%end

%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale {
    CGFloat s = getGlobalScale();
    %orig(s > 0.0 ? s : scale);
}
%end
