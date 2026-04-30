#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "device_detect.h"

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
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    // Máy ít RAM (dưới 3GB) thì dọn mạnh hơn
    if (deviceRAMGB() < 3.0) {
        [[NSURLCache sharedURLCache] setMemoryCapacity:0];
        [[NSURLCache sharedURLCache] setDiskCapacity:0];
    }
}

%hook UIApplication

- (void)didReceiveMemoryWarning {
    if (isRamOptEnabled()) {
        forceClearSystemCaches();
        %orig;
    } else {
        %orig;
    }
}

- (void)_performMemoryWarning {
    if (isRamOptEnabled()) {
        forceClearSystemCaches();
        %orig;
    } else {
        %orig;
    }
}

%end
