#import <Foundation/Foundation.h>

%hook NSURLSession

// Hook khi game gọi request mạng
- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_AnalyticsBlocker"];
    if (isEnabled && request.URL) {
        NSString *urlStr = request.URL.absoluteString.lowercaseString;
        
        // Danh sách đen các từ khóa theo dõi
        if ([urlStr containsString:@"analytics"] || 
            [urlStr containsString:@"tracking"] || 
            [urlStr containsString:@"metrics"] || 
            [urlStr containsString:@"telemetry"]) {
            
            // Bẻ lái request về bức tường localhost
            NSMutableURLRequest *mutReq = [request mutableCopy];
            mutReq.URL = [NSURL URLWithString:@"http://127.0.0.1"];
            return %orig(mutReq);
        }
    }
    return %orig;
}

// Hook tương tự với hàm nạp URL trực tiếp
- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_AnalyticsBlocker"];
    if (isEnabled && url) {
        NSString *urlStr = url.absoluteString.lowercaseString;
        
        if ([urlStr containsString:@"analytics"] || 
            [urlStr containsString:@"tracking"] || 
            [urlStr containsString:@"metrics"] || 
            [urlStr containsString:@"telemetry"]) {
            
            NSURL *fakeUrl = [NSURL URLWithString:@"http://127.0.0.1"];
            return %orig(fakeUrl);
        }
    }
    return %orig;
}

%end
