#pragma once
#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <OpenGLES/EAGL.h>

// ═══════════════════════════════════════════════
//   DEVICE DETECTOR — Runtime Hardware Check
//   Tự detect GPU, CPU để các file khác dùng
// ═══════════════════════════════════════════════

// ── GPU ──────────────────────────────────────
static BOOL deviceSupportsMetal() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        id<MTLDevice> device = MTLCreateSystemDefaultDevice();
        cached = (device != nil);
    });
    return cached;
}

static BOOL deviceSupportsOpenGLES() {
    // Mọi iPhone đều hỗ trợ OpenGL ES
    // Nhưng từ iOS 12 trở đi Apple deprecated, Metal là chính
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = (NSClassFromString(@"EAGLContext") != nil);
    });
    return cached;
}

// ── CPU ──────────────────────────────────────
static NSInteger deviceCPUCores() {
    static NSInteger cached = 0;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [NSProcessInfo processInfo].processorCount;
    });
    return cached;
}

// ── MEMORY ───────────────────────────────────
static uint64_t deviceRAMBytes() {
    static uint64_t cached = 0;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [NSProcessInfo processInfo].physicalMemory;
    });
    return cached;
}

// Tiện dùng hơn — trả về GB
static CGFloat deviceRAMGB() {
    return (CGFloat)deviceRAMBytes() / 1024.0 / 1024.0 / 1024.0;
}
