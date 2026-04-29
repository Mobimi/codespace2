#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

#define GO_SUITE @"com.universal.optimizer"

%hook CAMetalLayer

- (NSUInteger)maximumDrawableCount {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_InputLag"];
    if (!isEnabled) return %orig;

    // Đọc từ prefs — người dùng chọn 2 hoặc 3 từ menu
    // Mặc định 2 nếu chưa chọn lần nào
    NSInteger val = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                     integerForKey:@"GO_DrawableCount"];
    return (val == 3) ? 3 : 2;
}

%end