#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <OpenGLES/EAGL.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   RENDER OPTIMIZER — Metal + OpenGL ES
//   Tối ưu pipeline render, không đụng đến scale
//   hay maximumDrawableCount (đã có file khác lo)
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL renderOptEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_RenderOpt"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_RenderOpt"];
        }];
    });
    return cached;
}

// ── METAL LAYER ──────────────────────────────
%hook CAMetalLayer

- (BOOL)presentsWithTransaction {
    return renderOptEnabled() ? NO : %orig;
}

- (BOOL)framebufferOnly {
    return renderOptEnabled() ? YES : %orig;
}

// Đọc giá trị từ menu, mặc định 2 nếu chưa set
- (NSUInteger)maximumDrawableCount {
    if (!renderOptEnabled()) return %orig;
    NSInteger val = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                     integerForKey:@"GO_DrawableCount"];
    return (val == 3) ? 3 : 2;
}

%end

// ── OPENGL ES ────────────────────────────────
%hook EAGLContext

- (void)setMultiThreaded:(BOOL)multiThreaded {
    %orig(renderOptEnabled() ? YES : multiThreaded);
}

- (BOOL)multiThreaded {
    return renderOptEnabled() ? YES : %orig;
}

%end
