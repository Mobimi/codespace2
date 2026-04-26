#import <UIKit/UIKit.h>

%hook UIView
// Hook hàm tạo hiệu ứng cơ bản
+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_AnimKiller"];
    if (isEnabled) {
        // Ép thời gian (duration) về 0.0 giây
        %orig(0.0, animations); 
    } else {
        %orig;
    }
}

// Hook hàm tạo hiệu ứng nâng cao (có độ trễ delay)
+ (void)animateWithDuration:(NSTimeInterval)duration delay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_AnimKiller"];
    if (isEnabled) {
        // Ép cả thời gian chạy lẫn độ trễ về 0.0 giây
        %orig(0.0, 0.0, options, animations, completion);
    } else {
        %orig;
    }
}
%end
