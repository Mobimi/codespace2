#import <Foundation/Foundation.h>

// FIX: Gộp tất cả URL blocking vào đây, bao gồm cả Roblox telemetry
// Lý do: duplicate hook NSURLSession trong roblox.xm + network_blocker.xm
// gây crash trên iOS 18 với một số app mới (Substrate patch order không đảm bảo)

static BOOL shouldBlockURL(NSString *urlStr) {
    static NSArray *blockedKeywords = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        blockedKeywords = @[
            // General analytics
            @"analytics", @"tracking", @"metrics", @"telemetry",
            @"firebase", @"crashlytics", @"amplitude", @"appsflyer",
            @"adjust", @"segment",
            @"facebook.com/tr", @"graph.facebook.com",
            // Roblox telemetry (gộp từ roblox.xm)
            @"ephemeralcounters.roblox.com",
            @"ecsv2.roblox.com",
            @"clientsettingscdn.roblox.com",
            @"perf.roblox.com",
            @"diagnostics.roblox.com",
            // General Roblox analytics (từ blocklist cũ)
            @"roblox.com/analytics",
        ];
    });

    for (NSString *kw in blockedKeywords) {
        if ([urlStr containsString:kw]) return YES;
    }
    return NO;
}

// Helper kiểm tra công tắc - đọc 1 lần để tránh I/O trong hot path
static BOOL analyticsBlockerEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                  boolForKey:@"GO_AnalyticsBlocker"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                      boolForKey:@"GO_AnalyticsBlocker"];
        }];
    });
    return cached;
}

// FIX: Bổ sung GO_RobloxTelemetry check riêng
// Để 2 switch độc lập (Analytics + Roblox Telemetry) vẫn hoạt động đúng
static BOOL robloxTelemetryEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                  boolForKey:@"GO_RobloxTelemetry"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:@"com.universal.optimizer"]
                      boolForKey:@"GO_RobloxTelemetry"];
        }];
    });
    return cached;
}

static BOOL shouldBlock(NSURL *url) {
    if (!url) return NO;
    NSString *urlStr = url.absoluteString.lowercaseString;
    if (analyticsBlockerEnabled() && shouldBlockURL(urlStr)) return YES;
    if (robloxTelemetryEnabled() && shouldBlockURL(urlStr)) return YES;
    return NO;
}

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request
                            completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (shouldBlock(request.URL)) {
        NSMutableURLRequest *mutReq = [request mutableCopy];
        mutReq.URL = [NSURL URLWithString:@"http://127.0.0.1"];
        return %orig(mutReq, completionHandler);
    }
    return %orig;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url
                        completionHandler:(void (^)(NSData *, NSURLResponse *, NSError *))completionHandler {
    if (shouldBlock(url)) {
        return %orig([NSURL URLWithString:@"http://127.0.0.1"], completionHandler);
    }
    return %orig;
}

%end
