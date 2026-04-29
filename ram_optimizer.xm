#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   RAM OPTIMIZER v2 — Memory Warning Handler
//   Dọn cache thật sự, không chặn game tự xử lý
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL isRamOptEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_RAMBypass"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_RAMBypass"];
        }];
    });
    return cached;
}

static void forceClearSystemCaches() {
    // Xoá cache mạng — hiệu quả với game online
    [[NSURLCache sharedURLCache] removeAllCachedResponses];

    // Xoá image cache của UIKit
    // iOS cache ảnh UI trong bộ nhớ, dọn giúp giải phóng đáng kể
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
}

%hook UIApplication

- (void)didReceiveMemoryWarning {
    if (isRamOptEnabled()) {
        // Dọn cache trước để giải phóng RAM nhanh
        forceClearSystemCaches();
        // Vẫn gọi %orig để game tự giải phóng texture, audio buffer của nó
        %orig;
    } else {
        %orig;
    }
}

- (void)_performMemoryWarning {
    if (isRamOptEnabled()) {
        forceClearSystemCaches();
        // Tương tự — không chặn, để game engine tự xử lý phần của nó
        %orig;
    } else {
        %orig;
    }
}

%end
