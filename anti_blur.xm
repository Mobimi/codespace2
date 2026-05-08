#import <UIKit/UIKit.h>

// FIX: Gộp GO_RobloxPostFX vào đây thay vì hook UIVisualEffectView ở 2 chỗ
// roblox.xm cũ cũng hook UIVisualEffectView → trùng lặp trên iOS 18

%hook UIVisualEffectView
- (void)setEffect:(UIVisualEffect *)effect {
    BOOL antiBlur   = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                       boolForKey:@"GO_AntiBlur"];
    BOOL robloxPostFX = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                         boolForKey:@"GO_RobloxPostFX"];

    if (antiBlur || robloxPostFX) {
        %orig(nil);
    } else {
        %orig(effect);
    }
}
%end
