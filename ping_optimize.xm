#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet/tcp.h>
#import <substrate.h>

// ═══════════════════════════════════════════════
//   PING OPTIMIZER — Socket-Level QoS
//   Hook tầng socket thật, hiệu quả với UDP + TCP
// ═══════════════════════════════════════════════

#define GO_SUITE @"com.universal.optimizer"

static BOOL pingOptEnabled() {
    static BOOL cached = NO;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                  boolForKey:@"GO_PingOpt"];
        [[NSNotificationCenter defaultCenter]
            addObserverForName:NSUserDefaultsDidChangeNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            cached = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
                      boolForKey:@"GO_PingOpt"];
        }];
    });
    return cached;
}

static int (*orig_connect)(int, const struct sockaddr *, socklen_t);
static int replaced_connect(int fd, const struct sockaddr *addr, socklen_t len) {
    if (pingOptEnabled()) {
        // DSCP EF — ưu tiên cao nhất, router xử lý trước
        int tos = 0xB8;
        setsockopt(fd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));

        // Tắt Nagle algorithm — gửi gói ngay, không gom lại
        int noDelay = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &noDelay, sizeof(noDelay));
    }
    return orig_connect(fd, addr, len);
}

%ctor {
    MSHookFunction((void *)connect,
                   (void *)replaced_connect,
                   (void **)&orig_connect);
}
