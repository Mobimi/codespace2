#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet/tcp.h>

// ═══════════════════════════════════════════════
//   PING OPTIMIZER — Socket-Level QoS
//   Hook tầng socket thật, không phải NSURLSession
//   Hiệu quả với cả UDP (game engine) lẫn TCP
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

// ── HOOK TẦNG SOCKET ─────────────────────────
// connect() được gọi khi game mở socket đến server
// Đây là thời điểm tốt nhất để gắn QoS vào socket
int (*orig_connect)(int, const struct sockaddr *, socklen_t);
int replaced_connect(int fd, const struct sockaddr *addr, socklen_t len) {
    if (pingOptEnabled()) {
        // IP_TOS = 0xB8 (DSCP EF — Expedited Forwarding)
        // Đây là mức ưu tiên cao nhất trong mạng, dành cho VoIP và gaming
        // Router/modem nhận cờ này sẽ xử lý gói trước các gói thường
        int tos = 0xB8;
        setsockopt(fd, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));

        // TCP_NODELAY: tắt thuật toán Nagle
        // Nagle gom nhiều gói nhỏ lại gửi 1 lần để tiết kiệm băng thông
        // Với game real-time điều này gây thêm ~20-40ms delay không cần thiết
        int noDelay = 1;
        setsockopt(fd, IPPROTO_TCP, TCP_NODELAY, &noDelay, sizeof(noDelay));

        // SO_PRIORITY: ưu tiên socket ở tầng kernel
        // Giá trị 6 = cao nhất không cần root đặc biệt
        int prio = 6;
        setsockopt(fd, SOL_SOCKET, SO_PRIORITY, &prio, sizeof(prio));
    }
    return orig_connect(fd, addr, len);
}

// ── KHỞI TẠO ─────────────────────────────────
%ctor {
    // MSHookFunction hook thẳng vào hàm C của hệ thống
    // Không dùng %hook vì connect() không phải Objective-C method
    MSHookFunction((void *)connect,
                   (void *)replaced_connect,
                   (void **)&orig_connect);
}
