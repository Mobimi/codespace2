#import <Foundation/Foundation.h>

// Hàm helper để check từ khóa cực nhanh, tách ra đây để dùng chung cho 2 hàm Hook bên dưới
static BOOL shouldBlockURL(NSString *urlStr) {
    // Danh sách đen tổng hợp (vừa có của sếp, vừa có của Claude)
    NSArray *blockedKeywords = @[
        @"analytics", @"tracking", @"metrics", @"telemetry",
        @"firebase", @"crashlytics", @"amplitude", @"appsflyer",
        @"adjust", @"segment", @"roblox.com/analytics",
        @"facebook.com/tr", @"graph.facebook.com"
    ];
    
    for (NSString *keyword in blockedKeywords) {
        if ([urlStr containsString:keyword]) {
            return YES; // Bắt được quả tang gián điệp!
        }
    }
    return NO;
}

%hook NSURLSession

// Hook khi game gọi request mạng (Dạng Request)
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    // Dùng Két sắt (SuiteName) để đồng bộ mọi game như Claude báo
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
    BOOL isEnabled = [defaults boolForKey:@"GO_AnalyticsBlocker"];
    
    if (isEnabled && request.URL) {
        NSString *urlStr = request.URL.absoluteString.lowercaseString;
        
        if (shouldBlockURL(urlStr)) {
            // Bẻ lái request gián điệp úp mặt vào tường (localhost)
            NSMutableURLRequest *mutReq = [request mutableCopy];
            mutReq.URL = [NSURL URLWithString:@"http://127.0.0.1"];
            return %orig(mutReq);
        }
    }
    return %orig;
}

// Hook tương tự với hàm nạp URL trực tiếp (Dạng URL)
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"];
    BOOL isEnabled = [defaults boolForKey:@"GO_AnalyticsBlocker"];
    
    if (isEnabled && url) {
        NSString *urlStr = url.absoluteString.lowercaseString;
        
        if (shouldBlockURL(urlStr)) {
            NSURL *fakeUrl = [NSURL URLWithString:@"http://127.0.0.1"];
            return %orig(fakeUrl);
        }
    }
    return %orig;
}

%end
