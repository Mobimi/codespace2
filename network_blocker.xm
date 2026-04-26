#import <Foundation/Foundation.h>

// [TỐI ƯU THEO CLAUDE]: Khởi tạo Mảng từ khóa 1 lần duy nhất để không làm rác RAM
static BOOL shouldBlockURL(NSString *urlStr) {
    static NSArray *blockedKeywords = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        blockedKeywords = @[
            @"analytics", @"tracking", @"metrics", @"telemetry",
            @"firebase", @"crashlytics", @"amplitude", @"appsflyer",
            @"adjust", @"segment", @"roblox.com/analytics", 
            @"facebook.com/tr", @"graph.facebook.com"
        ];
    });
    
    for (NSString *kw in blockedKeywords) {
        if ([urlStr containsString:kw]) return YES;
    }
    return NO;
}

%hook NSURLSession

// Hook Request
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_AnalyticsBlocker"];
    
    if (isEnabled && request.URL && shouldBlockURL(request.URL.absoluteString.lowercaseString)) {
        NSMutableURLRequest *mutReq = [request mutableCopy];
        mutReq.URL = [NSURL URLWithString:@"http://127.0.0.1"];
        return %orig(mutReq);
    }
    return %orig;
}

// Hook URL
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    BOOL isEnabled = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"] boolForKey:@"GO_AnalyticsBlocker"];
    
    if (isEnabled && url && shouldBlockURL(url.absoluteString.lowercaseString)) {
        return %orig([NSURL URLWithString:@"http://127.0.0.1"]);
    }
    return %orig;
}

%end
