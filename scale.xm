#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

// Cache vào RAM, chỉ đọc disk 1 lần duy nhất
static CGFloat cachedScale = -1.0;

static CGFloat getGlobalScale() {
    if (cachedScale == -1.0) {
        float saved = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                       floatForKey:@"GO_Scale"];
        cachedScale = (saved > 0.1) ? (CGFloat)saved : 0.0;
    }
    return cachedScale;
}

// Gọi hàm này khi user bấm Apply trong ImGui menu
void updateGlobalScale(CGFloat newScale) {
    cachedScale = newScale;
    [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
     setFloat:newScale forKey:@"GO_Scale"];
}

%hook UIScreen
- (CGFloat)scale { CGFloat s = getGlobalScale(); return s > 0.0 ? s : %orig; }
- (CGFloat)nativeScale { CGFloat s = getGlobalScale(); return s > 0.0 ? s : %orig; }
%end

%hook UIWindow
- (void)setContentScaleFactor:(CGFloat)scale { %orig(getGlobalScale()); }
%end

%hook UIView
- (void)setContentScaleFactor:(CGFloat)scale { %orig(getGlobalScale()); }
%end

%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale { %orig(getGlobalScale()); }
%end

%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale { %orig(getGlobalScale()); }
%end
