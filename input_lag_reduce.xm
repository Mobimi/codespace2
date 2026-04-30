#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import "device_detect.h"

#define GO_SUITE @"com.universal.optimizer"

%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_InputLag"];
    if (!isEnabled) return %orig;
    if (!deviceSupportsMetal()) return %orig; // máy không có Metal thì bỏ qua
    NSInteger val = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                     integerForKey:@"GO_DrawableCount"];
    return (val == 3) ? 3 : 2;
}

%end
