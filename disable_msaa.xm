#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   MSAA DISABLER — GPU Load Reducer
//   Tắt Multi-Sample Anti-Aliasing để GPU nhẹ hơn
//   FPS tăng rõ, đánh đổi cạnh hơi răng cưa hơn
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL msaaDisableEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_MSAADisable"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_MSAADisable"];
        }];
    });
    return cached;
}

%hook CAMetalLayer

- (NSUInteger)sampleCount {
    // sampleCount = 1 tức là tắt hoàn toàn MSAA
    // Mặc định iOS thường là 4 (4x MSAA)
    return msaaDisableEnabled() ? 1 : %orig;
}

%end
