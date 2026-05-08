#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   ROBLOX OPTIMIZER
//   Tối ưu đặc thù cho Roblox engine
//   FIX: Bỏ hook NSURLSession ở đây vì network_blocker.xm đã handle
//   Duplicate hook cùng method trên iOS 18 → crash không có log rõ
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL robloxPostFXEnabled() {
    return [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
            boolForKey:@"GO_RobloxPostFX"];
}
static BOOL robloxLowTexEnabled() {
    return [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
            boolForKey:@"GO_RobloxLowTex"];
}

// FIX: Telemetry Roblox giờ được xử lý qua network_blocker.xm
// Thêm các domain Roblox vào blockedKeywords trong network_blocker.xm thay vì hook lại ở đây

// ── Tắt post-processing / blur ──
// FIX: Không hook UIVisualEffectView ở đây vì anti_blur.xm đã hook rồi
// Gộp logic: GO_RobloxPostFX || GO_AntiBlur đều tắt blur
// → Xử lý trong anti_blur.xm (xem file đó)

// ── Giảm texture quality ──
%hook UIImage
+ (UIImage *)imageNamed:(NSString *)name {
    if (!robloxLowTexEnabled()) return %orig;
    if ([name hasPrefix:@"rbx"] || [name hasPrefix:@"roblox"] || [name hasPrefix:@"Roblox"]) {
        UIImage *img = %orig;
        if (!img) return nil;
        // FIX: scale:1.0 làm giảm resolution thực sự nhưng dùng
        // UIGraphicsImageRendererFormat để tương thích iOS 15+
        UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat preferredFormat];
        fmt.scale = 1.0;
        fmt.opaque = NO;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc]
                                             initWithSize:img.size format:fmt];
        UIImage *lowRes = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
        }];
        return lowRes ?: img;
    }
    return %orig;
}
%end
