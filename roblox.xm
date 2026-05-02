#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   ROBLOX OPTIMIZER
//   Tối ưu đặc thù cho Roblox engine
//   Yêu cầu khởi động lại app để áp dụng
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL robloxPostFXEnabled() {
    return [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
            boolForKey:@"GO_RobloxPostFX"];
}
static BOOL robloxTelemetryEnabled() {
    return [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
            boolForKey:@"GO_RobloxTelemetry"];
}
static BOOL robloxLowTexEnabled() {
    return [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
            boolForKey:@"GO_RobloxLowTex"];
}

// ── Chặn telemetry ──
%hook NSURLSession
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                           completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (robloxTelemetryEnabled() && request.URL) {
        NSString *host = request.URL.host.lowercaseString;
        NSArray *blocked = @[
            @"ephemeralcounters.roblox.com",
            @"ecsv2.roblox.com",
            @"clientsettingscdn.roblox.com",
            @"perf.roblox.com",
            @"diagnostics.roblox.com",
        ];
        for (NSString *domain in blocked) {
            if ([host hasSuffix:domain]) {
                if (completionHandler) {
                    completionHandler(nil, nil, [NSError errorWithDomain:NSURLErrorDomain
                                                                    code:NSURLErrorCancelled
                                                                userInfo:nil]);
                }
                return %orig(request, completionHandler);
            }
        }
    }
    return %orig;
}
%end

// ── Tắt post-processing / blur ──
%hook UIVisualEffectView
- (void)setEffect:(UIVisualEffect *)effect {
    robloxPostFXEnabled() ? %orig(nil) : %orig;
}
%end

// ── Giảm texture quality ──
%hook UIImage
+ (UIImage *)imageNamed:(NSString *)name {
    if (!robloxLowTexEnabled()) return %orig;
    if ([name hasPrefix:@"rbx"] || [name hasPrefix:@"roblox"] || [name hasPrefix:@"Roblox"]) {
        UIImage *img = %orig;
        if (!img) return nil;
        UIGraphicsBeginImageContextWithOptions(img.size, NO, 1.0);
        [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
        UIImage *lowRes = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return lowRes ?: img;
    }
    return %orig;
}
%end
