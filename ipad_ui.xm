#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// ═══════════════════════════════════════════════
//   IPAD UI — Force iPad Layout
//   Ép game load giao diện iPad, không tốn thêm GPU
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL ipadUIEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_iPadUI"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_iPadUI"];
        }];
    });
    return cached;
}

%hook UIDevice

- (UIUserInterfaceIdiom)userInterfaceIdiom {
    return ipadUIEnabled() ? UIUserInterfaceIdiomPad : %orig;
}

%end

%hook UITraitCollection

- (UIUserInterfaceIdiom)userInterfaceIdiom {
    return ipadUIEnabled() ? UIUserInterfaceIdiomPad : %orig;
}

%end
