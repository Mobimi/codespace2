#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig; // Bắt buộc phải gọi orig để không hỏng app
    
    // Dồn tài nguyên CPU cho luồng chạy game
    NSThread *mainThread = [NSThread mainThread];
    if ([mainThread respondsToSelector:@selector(setQualityOfService:)]) {
        [mainThread setQualityOfService:NSQualityOfServiceUserInteractive];
    }
    [mainThread setThreadPriority:1.0];
}
%end
