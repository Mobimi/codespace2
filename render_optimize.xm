#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <OpenGLES/EAGL.h>
#import <Foundation/Foundation.h>
#import "device_detect.h"

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

%hook CAMetalLayer

- (BOOL)presentsWithTransaction {
    if (!renderOptEnabled()) return %orig;
    return deviceSupportsMetal() ? NO : %orig;
}

- (BOOL)framebufferOnly {
    if (!renderOptEnabled()) return %orig;
    return deviceSupportsMetal() ? YES : %orig;
}

%end

%hook EAGLContext

- (void)setMultiThreaded:(BOOL)multiThreaded {
    if (!renderOptEnabled()) { %orig; return; }
    %orig(deviceSupportsOpenGLES() ? YES : multiThreaded);
}

- (BOOL)multiThreaded {
    if (!renderOptEnabled()) return %orig;
    return deviceSupportsOpenGLES() ? YES : %orig;
}

%end
