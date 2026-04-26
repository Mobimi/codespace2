#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>

// ==========================================
// COMPONENT 1: VÒNG TRÒN CPU & RAM (Giữ nguyên)
// ==========================================
@interface HUDCircleView : UIView
@property (nonatomic, strong) CAShapeLayer *bgLayer, *progressLayer;
@property (nonatomic, strong) UILabel *titleLabel, *valueLabel;
- (void)updateWithProgress:(CGFloat)progress valueText:(NSString *)text;
@end

@implementation HUDCircleView
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (self) {
        CGFloat radius = frame.size.width / 2.0 - 4;
        CGPoint center = CGPointMake(frame.size.width / 2.0, frame.size.width / 2.0);
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI_2 * 3 clockwise:YES];

        self.bgLayer = [CAShapeLayer layer];
        self.bgLayer.path = circlePath.CGPath;
        self.bgLayer.fillColor = [UIColor clearColor].CGColor;
        self.bgLayer.strokeColor = [UIColor colorWithWhite:0.5 alpha:0.5].CGColor;
        self.bgLayer.lineWidth = 2.5;
        [self.layer addSublayer:self.bgLayer];

        self.progressLayer = [CAShapeLayer layer];
        self.progressLayer.path = circlePath.CGPath;
        self.progressLayer.fillColor = [UIColor clearColor].CGColor;
        self.progressLayer.strokeColor = [UIColor greenColor].CGColor;
        self.progressLayer.lineWidth = 2.5;
        self.progressLayer.strokeEnd = 0.0; 
        self.progressLayer.lineCap = kCALineCapRound;
        [self.layer addSublayer:self.progressLayer];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.width)];
        self.titleLabel.text = title;
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:9];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];

        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(-10, frame.size.width - 2, frame.size.width + 20, 15)];
        self.valueLabel.textColor = [UIColor whiteColor];
        self.valueLabel.font = [UIFont boldSystemFontOfSize:9];
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.valueLabel];
    }
    return self;
}
- (void)updateWithProgress:(CGFloat)progress valueText:(NSString *)text {
    if (progress > 1.0) progress = 1.0; if (progress < 0.0) progress = 0.0;
    self.progressLayer.strokeEnd = progress;
    CGFloat hue = (1.0 - progress) * 0.33; 
    self.progressLayer.strokeColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0].CGColor;
    self.valueLabel.text = text;
}
@end

// ==========================================
// COMPONENT 2: BẢNG HUD (ĐÃ BIẾN THÀNH UIVIEW)
// ==========================================
@interface PerformanceHUDView : UIView
@property (nonatomic, strong) UILabel *fpsTitle, *fpsValue;
@property (nonatomic, strong) HUDCircleView *cpuView, *ramView;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
+ (instancetype)shared;
- (void)checkState;
@end

@implementation PerformanceHUDView
+ (instancetype)shared {
    static PerformanceHUDView *hud = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        // Bản thân view này chính là cái bảng HUD luôn
        hud = [[PerformanceHUDView alloc] initWithFrame:CGRectMake(20, 100, 145, 55)];
    });
    return hud;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        self.layer.cornerRadius = 12;
        self.layer.masksToBounds = YES;

        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:pan]; 

        self.fpsTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 8, 45, 15)];
        self.fpsTitle.text = @"FPS"; self.fpsTitle.textColor = [UIColor lightGrayColor];
        self.fpsTitle.font = [UIFont boldSystemFontOfSize:10]; self.fpsTitle.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.fpsTitle];

        self.fpsValue = [[UILabel alloc] initWithFrame:CGRectMake(5, 22, 45, 25)];
        self.fpsValue.textColor = [UIColor greenColor]; self.fpsValue.font = [UIFont boldSystemFontOfSize:18];
        self.fpsValue.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.fpsValue];

        self.cpuView = [[HUDCircleView alloc] initWithFrame:CGRectMake(55, 6, 35, 35) title:@"CPU"];
        [self addSubview:self.cpuView];

        self.ramView = [[HUDCircleView alloc] initWithFrame:CGRectMake(100, 6, 35, 35) title:@"RAM"];
        [self addSubview:self.ramView];

        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        self.displayLink.paused = YES; // Tắt mặc định
        self.hidden = YES; // Ẩn mặc định

        // Lắng nghe lệnh từ Menu
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkState) name:@"GO_ToggleHUD" object:nil];
    }
    return self;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.superview];
    self.center = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self.superview];
}

// Hàm dán thẳng vào mặt Game khi gạt công tắc
- (void)checkState {
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL isEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_PerfHUD"];
        
        if (isEnabled) {
            // Tìm cửa sổ xịn nhất của Game để dán vào
            UIWindow *gameWindow = [UIApplication sharedApplication].keyWindow;
            if (!gameWindow) gameWindow = [UIApplication sharedApplication].windows.firstObject;
            
            if (gameWindow && self.superview != gameWindow) {
                [gameWindow addSubview:self];
            }
            // Ép nó luôn nằm trên cùng (đỡ bị game che)
            if (self.superview) [self.superview bringSubviewToFront:self];
            
            self.hidden = NO;
            self.displayLink.paused = NO;
        } else {
            self.hidden = YES;
            self.displayLink.paused = YES;
            [self removeFromSuperview]; // Gỡ miếng dán ra cho nhẹ nợ
        }
    });
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) { self.lastTime = link.timestamp; return; }
    self.count++; NSTimeInterval delta = link.timestamp - self.lastTime;
    if (delta >= 1.0) {
        double fps = self.count / delta; self.count = 0; self.lastTime = link.timestamp;
        self.fpsValue.text = [NSString stringWithFormat:@"%.0f", fps];

        struct mach_task_basic_info info; mach_msg_type_number_t size = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO, (task_info_t)&info, &size);
        double ramMB = (kerr == KERN_SUCCESS) ? (info.resident_size / 1024.0 / 1024.0) : 0;
        [self.ramView updateWithProgress:(ramMB / 6144.0) valueText:[NSString stringWithFormat:@"%.0f MB", ramMB]];

        thread_array_t thread_list; mach_msg_type_number_t thread_count; thread_info_data_t thinfo;
        mach_msg_type_number_t thread_info_count; thread_basic_info_t basic_info_th;
        kerr = task_threads(mach_task_self(), &thread_list, &thread_count); float total_cpu = 0;
        if (kerr == KERN_SUCCESS) {
            for (int j = 0; j < thread_count; j++) {
                thread_info_count = THREAD_INFO_MAX; kerr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
                if (kerr == KERN_SUCCESS) { basic_info_th = (thread_basic_info_t)thinfo; if (!(basic_info_th->flags & TH_FLAGS_IDLE)) total_cpu += basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0; }
            }
            vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
        }
        NSUInteger numCores = [[NSProcessInfo processInfo] activeProcessorCount];
        float normalized_cpu = total_cpu / numCores; if (normalized_cpu > 100.0) normalized_cpu = 100.0; 
        [self.cpuView updateWithProgress:(normalized_cpu / 100.0) valueText:[NSString stringWithFormat:@"%.0f%%", normalized_cpu]];
    }
}
@end

// ==========================================
// COMPONENT 3: TIÊM VÀO GAME
// ==========================================
%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Chỉ cần gọi shared để nó khởi tạo và vểnh tai nghe lệnh từ Menu
            [[PerformanceHUDView shared] checkState]; 
        });
    });
}
%end
