#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <mach/mach.h>

#define GO_SUITE @"com.universal.optimizer"

// ==========================================
// COMPONENT 1: VÒNG TRÒN CPU & RAM
// ==========================================
@interface HUDCircleView : UIView
@property (nonatomic, strong) CAShapeLayer *bgLayer;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *valueLabel;
@end

@implementation HUDCircleView
- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    CGFloat radius = frame.size.width / 2.0 - 4;
    CGPoint center = CGPointMake(frame.size.width / 2.0, frame.size.width / 2.0);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:center
                                                              radius:radius
                                                          startAngle:-M_PI_2
                                                            endAngle:M_PI_2 * 3
                                                           clockwise:YES];

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

    return self;
}

- (void)updateWithProgress:(CGFloat)progress valueText:(NSString *)text {
    progress = MAX(0.0, MIN(1.0, progress));
    self.progressLayer.strokeEnd = progress;
    CGFloat hue = (1.0 - progress) * 0.33;
    self.progressLayer.strokeColor = [UIColor colorWithHue:hue saturation:1.0 brightness:1.0 alpha:1.0].CGColor;
    self.valueLabel.text = text;
}
@end

// ==========================================
// COMPONENT 2: ROOT VIEW CONTROLLER
// ==========================================
@interface HUDRootVC : UIViewController
@end

@implementation HUDRootVC
- (BOOL)prefersStatusBarHidden { return YES; }

- (UIViewController *)gameRootVC {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = (UIWindowScene *)self.view.window.windowScene;
        for (UIWindow *w in scene.windows) {
            if (w != self.view.window && w.rootViewController) {
                return w.rootViewController;
            }
        }
    }
    return nil;
}

- (BOOL)shouldAutorotate {
    UIViewController *vc = [self gameRootVC];
    return vc ? [vc shouldAutorotate] : YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *vc = [self gameRootVC];
    return vc ? [vc supportedInterfaceOrientations] : UIInterfaceOrientationMaskAll;
}
@end

// ==========================================
// COMPONENT 3: HUD WINDOW
// ==========================================
@interface PerformanceHUDWindow : UIWindow
@property (nonatomic, strong) UIView         *hudPanel;
@property (nonatomic, strong) UILabel        *fpsTitle;
@property (nonatomic, strong) UILabel        *fpsValue;
@property (nonatomic, strong) HUDCircleView  *cpuView;
@property (nonatomic, strong) HUDCircleView  *ramView;
@property (nonatomic, strong) CADisplayLink  *displayLink;
@property (nonatomic, assign) NSTimeInterval  lastTime;
@property (nonatomic, assign) NSUInteger      frameCount;
@property (nonatomic, assign) uint64_t        totalRAM;
@end

@implementation PerformanceHUDWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.windowLevel     = UIWindowLevelStatusBar + 99;
    self.backgroundColor = [UIColor clearColor];

    // FIX: Đọc tổng RAM động thay vì hardcode 6144MB
    self.totalRAM = [NSProcessInfo processInfo].physicalMemory;

    // Panel chính
    self.hudPanel = [[UIView alloc] initWithFrame:CGRectMake(20, 50, 145, 55)];
    self.hudPanel.backgroundColor    = [UIColor colorWithWhite:0.0 alpha:0.4];
    self.hudPanel.layer.cornerRadius = 12;
    self.hudPanel.layer.masksToBounds = YES;
    [self addSubview:self.hudPanel];

    // FIX: Pan gesture gắn vào hudPanel thay vì window
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    [self.hudPanel addGestureRecognizer:pan];

    // FPS
    self.fpsTitle = [[UILabel alloc] initWithFrame:CGRectMake(5, 8, 45, 15)];
    self.fpsTitle.text          = @"FPS";
    self.fpsTitle.textColor     = [UIColor lightGrayColor];
    self.fpsTitle.font          = [UIFont boldSystemFontOfSize:10];
    self.fpsTitle.textAlignment = NSTextAlignmentCenter;
    [self.hudPanel addSubview:self.fpsTitle];

    self.fpsValue = [[UILabel alloc] initWithFrame:CGRectMake(5, 22, 45, 25)];
    self.fpsValue.text          = @"--";
    self.fpsValue.textColor     = [UIColor greenColor];
    self.fpsValue.font          = [UIFont boldSystemFontOfSize:18];
    self.fpsValue.textAlignment = NSTextAlignmentCenter;
    [self.hudPanel addSubview:self.fpsValue];

    // Vòng tròn
    self.cpuView = [[HUDCircleView alloc] initWithFrame:CGRectMake(55, 6, 35, 35) title:@"CPU"];
    [self.hudPanel addSubview:self.cpuView];

    self.ramView = [[HUDCircleView alloc] initWithFrame:CGRectMake(100, 6, 35, 35) title:@"RAM"];
    [self.hudPanel addSubview:self.ramView];

    // DisplayLink
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    // Lắng nghe toggle từ menu
    [[NSNotificationCenter defaultCenter]
        addObserverForName:NSUserDefaultsDidChangeNotification
                    object:nil
                     queue:[NSOperationQueue mainQueue]
                usingBlock:^(NSNotification *n) {
        BOOL on = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE] boolForKey:@"GO_PerfHUD"];
        self.hudPanel.hidden    = !on;
        self.displayLink.paused = !on;
    }];

    // Trạng thái ban đầu
    BOOL on = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE] boolForKey:@"GO_PerfHUD"];
    self.hudPanel.hidden    = !on;
    self.displayLink.paused = !on;

    return self;
}

// FIX: pointInside chỉ nhận touch trong hudPanel
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return !self.hudPanel.hidden && CGRectContainsPoint(self.hudPanel.frame, point);
}

// FIX: Pan có bounds clamping
- (void)handlePan:(UIPanGestureRecognizer *)r {
    CGPoint p = [r translationInView:self];
    CGPoint newCenter = CGPointMake(self.hudPanel.center.x + p.x,
                                    self.hudPanel.center.y + p.y);
    CGFloat halfW = self.hudPanel.frame.size.width  / 2;
    CGFloat halfH = self.hudPanel.frame.size.height / 2;
    newCenter.x = MAX(halfW, MIN(self.frame.size.width  - halfW, newCenter.x));
    newCenter.y = MAX(halfH, MIN(self.frame.size.height - halfH, newCenter.y));
    self.hudPanel.center = newCenter;
    [r setTranslation:CGPointZero inView:self];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) { self.lastTime = link.timestamp; return; }
    self.frameCount++;
    NSTimeInterval delta = link.timestamp - self.lastTime;

    if (delta >= 1.0) {
        // FPS
        double fps = self.frameCount / delta;
        self.frameCount = 0;
        self.lastTime   = link.timestamp;

        UIColor *fpsColor;
        if (fps >= 55)      fpsColor = [UIColor greenColor];
        else if (fps >= 30) fpsColor = [UIColor yellowColor];
        else                fpsColor = [UIColor redColor];
        self.fpsValue.textColor = fpsColor;
        self.fpsValue.text = [NSString stringWithFormat:@"%.0f", fps];

        // RAM
        struct mach_task_basic_info info;
        mach_msg_type_number_t sz = MACH_TASK_BASIC_INFO_COUNT;
        kern_return_t kerr = task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                                       (task_info_t)&info, &sz);
        if (kerr == KERN_SUCCESS) {
            double ramMB   = info.resident_size / 1024.0 / 1024.0;
            double totalMB = self.totalRAM / 1024.0 / 1024.0;
            [self.ramView updateWithProgress:(ramMB / totalMB)
                                   valueText:[NSString stringWithFormat:@"%.0fM", ramMB]];
        }

        // CPU
        thread_array_t thread_list;
        mach_msg_type_number_t thread_count;
        kerr = task_threads(mach_task_self(), &thread_list, &thread_count);
        float total_cpu = 0;
        if (kerr == KERN_SUCCESS) {
            for (int j = 0; j < (int)thread_count; j++) {
                thread_info_data_t     thinfo;
                mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
                kerr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                                   (thread_info_t)thinfo, &thread_info_count);
                if (kerr == KERN_SUCCESS) {
                    thread_basic_info_t basic = (thread_basic_info_t)thinfo;
                    if (!(basic->flags & TH_FLAGS_IDLE))
                        total_cpu += basic->cpu_usage / (float)TH_USAGE_SCALE * 100.0f;
                }
            }
            vm_deallocate(mach_task_self(), (vm_offset_t)thread_list,
                          thread_count * sizeof(thread_t));
        }

        NSUInteger cores     = [[NSProcessInfo processInfo] activeProcessorCount];
        float normalized     = MIN(total_cpu / (float)cores, 100.0f);
        [self.cpuView updateWithProgress:(normalized / 100.0f)
                               valueText:[NSString stringWithFormat:@"%.0f%%", normalized]];
    }
}

- (void)dealloc {
    [self.displayLink invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

// ==========================================
// COMPONENT 4: INJECTION
// ==========================================
static PerformanceHUDWindow *hudWindow;

%ctor {
    @autoreleasepool {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        BOOL isUserApp = [path containsString:@"/Application/"] ||
                         [path containsString:@"/Containers/"];
        if (!isUserApp) return;

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                UIWindowScene *scene = nil;
                for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                    if (s.activationState == UISceneActivationStateForegroundActive &&
                        [s isKindOfClass:[UIWindowScene class]]) {
                        scene = (UIWindowScene *)s;
                        break;
                    }
                }
                hudWindow = [[PerformanceHUDWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                hudWindow.rootViewController = [[HUDRootVC alloc] init];
                if (scene) hudWindow.windowScene = scene;
                hudWindow.hidden = NO;
            });
        }];
    }
}
