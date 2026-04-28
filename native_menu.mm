#import <UIKit/UIKit.h>

// ═══════════════════════════════════════════════
//   UNIVERSAL OPTIMIZER — NATIVE UI MENU v3.1
//   Tối ưu bởi Claude: Fix recursion, fix gesture,
//   tối ưu memory, iOS 13+ WindowScene support
// ═══════════════════════════════════════════════

#define GO_SUITE  @"com.universal.optimizer"
#define GO_PREFS  [[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]

// Bảng màu Dark Mode phong cách Hacker
#define CLR_BG     [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.95]
#define CLR_ROW    [UIColor colorWithRed:0.12 green:0.14 blue:0.18 alpha:1.00]
#define CLR_ACCENT [UIColor colorWithRed:0.00 green:0.85 blue:1.00 alpha:1.00]
#define CLR_TEXT   [UIColor colorWithWhite:0.95 alpha:1.00]

// ── Scale mặc định an toàn (Không gọi UIScreen.scale để tránh infinite loop) ──
static CGFloat safeDefaultScale() {
    float saved = [[[NSUserDefaults alloc] initWithSuiteName:GO_SUITE] floatForKey:@"GO_Scale"];
    return (saved > 0.1f) ? (CGFloat)saved : 3.0f; // 3.0 = native scale iPhone 12 Pro Max
}

// ═══════════════════════════════════════════════
@interface GOMenuViewController : UIViewController
@end

@implementation GOMenuViewController
- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }
- (BOOL)prefersStatusBarHidden { return YES; }
@end

// ═══════════════════════════════════════════════
@interface GOMenuWindow : UIWindow
@property (nonatomic, strong) UIButton      *floatingBtn;
@property (nonatomic, strong) UIView        *menuPanel;
@property (nonatomic, strong) UIScrollView  *scrollView;
@property (nonatomic, strong) UITextField   *scaleInput;
@end

@implementation GOMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.windowLevel    = UIWindowLevelStatusBar + 100;
    self.backgroundColor = [UIColor clearColor];
    self.rootViewController = [[GOMenuViewController alloc] init];

    [self setupFloatingButton];
    [self setupMenuPanel];

    return self;
}

// ── CẢM ỨNG XUYÊN THẤU ──
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden &&
        CGRectContainsPoint(self.floatingBtn.frame, point)) {
        return self.floatingBtn;
    }
    if (!self.menuPanel.hidden &&
        CGRectContainsPoint(self.menuPanel.frame, point)) {
        return [self.menuPanel hitTest:[self convertPoint:point toView:self.menuPanel]
                             withEvent:event];
    }
    return nil; // Xuyên qua cho game
}

// ── NÚT GỌI MENU ──
- (void)setupFloatingButton {
    self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingBtn.frame = CGRectMake(20, 100, 48, 48);
    self.floatingBtn.backgroundColor = CLR_BG;
    self.floatingBtn.layer.cornerRadius = 24;
    self.floatingBtn.layer.borderWidth  = 1.5;
    self.floatingBtn.layer.borderColor  = CLR_ACCENT.CGColor;
    // Shadow nhẹ cho nổi bật hơn
    self.floatingBtn.layer.shadowColor   = CLR_ACCENT.CGColor;
    self.floatingBtn.layer.shadowOffset  = CGSizeZero;
    self.floatingBtn.layer.shadowRadius  = 6;
    self.floatingBtn.layer.shadowOpacity = 0.5;
    [self.floatingBtn setTitle:@"⚙️" forState:UIControlStateNormal];
    [self.floatingBtn addTarget:self
                         action:@selector(toggleMenu)
               forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(panButton:)];
    [self.floatingBtn addGestureRecognizer:pan];

    [self addSubview:self.floatingBtn];
}

// ── BẢNG MENU CHÍNH ──
- (void)setupMenuPanel {
    self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 280, 330)];
    self.menuPanel.center = CGPointMake(self.frame.size.width / 2,
                                        self.frame.size.height / 2);
    self.menuPanel.backgroundColor      = CLR_BG;
    self.menuPanel.layer.cornerRadius   = 14;
    self.menuPanel.layer.borderWidth    = 1.5;
    self.menuPanel.layer.borderColor    = CLR_ACCENT.CGColor;
    self.menuPanel.layer.shadowColor    = [UIColor blackColor].CGColor;
    self.menuPanel.layer.shadowOffset   = CGSizeMake(0, 4);
    self.menuPanel.layer.shadowRadius   = 12;
    self.menuPanel.layer.shadowOpacity  = 0.6;
    self.menuPanel.hidden = YES;

    // Tiêu đề
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 280, 42)];
    title.text          = @"✦ UNIVERSAL OPTIMIZER ✦";
    title.textColor     = CLR_ACCENT;
    title.font          = [UIFont boldSystemFontOfSize:13];
    title.textAlignment = NSTextAlignmentCenter;
    [self.menuPanel addSubview:title];

    // Đường kẻ phân cách dưới title
    UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(10, 42, 260, 0.5)];
    sep.backgroundColor = CLR_ACCENT;
    sep.alpha = 0.4;
    [self.menuPanel addSubview:sep];

    // Nút đóng
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(246, 6, 28, 28);
    [closeBtn setTitle:@"✖" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [closeBtn addTarget:self
                 action:@selector(toggleMenu)
       forControlEvents:UIControlEventTouchUpInside];
    [self.menuPanel addSubview:closeBtn];

    // ScrollView
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 48, 260, 272)];
    self.scrollView.showsVerticalScrollIndicator = YES;
    self.scrollView.alwaysBounceVertical = YES;
    [self.menuPanel addSubview:self.scrollView];

    [self populateMenu];

    // Pan gesture kéo menu — KHÔNG xung đột với scroll
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(panMenu:)];
    [pan requireGestureRecognizerToFail:self.scrollView.panGestureRecognizer];
    [self.menuPanel addGestureRecognizer:pan];

    [self addSubview:self.menuPanel];
}

- (void)populateMenu {
    NSArray *features = @[
        @{@"name": @"⚡  CPU Priority Boost",  @"key": @"GO_CPUPriority"},
        @{@"name": @"🎯  Input Lag Reduce",    @"key": @"GO_InputLag"},
        @{@"name": @"💾  RAM Warn Bypass",     @"key": @"GO_RAMBypass"},
        @{@"name": @"🌡  Anti-Throttling",     @"key": @"GO_ThermalBypass"},
        @{@"name": @"✂️  UI Anim Killer",      @"key": @"GO_AnimKiller"},
        @{@"name": @"🔍  Anti-Blur GPU",       @"key": @"GO_AntiBlur"},
        @{@"name": @"🛡  Block Analytics",     @"key": @"GO_AnalyticsBlocker"},
    ];

    NSUserDefaults *prefs = GO_PREFS;
    CGFloat yOffset = 0;

    // ── Scale Row ──
    UIView *scaleRow = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, 260, 44)];
    scaleRow.backgroundColor    = CLR_ROW;
    scaleRow.layer.cornerRadius = 8;

    UILabel *scaleLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 55, 44)];
    scaleLbl.text      = @"Scale";
    scaleLbl.textColor = CLR_TEXT;
    scaleLbl.font      = [UIFont systemFontOfSize:13];
    [scaleRow addSubview:scaleLbl];

    self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(68, 7, 110, 30)];
    self.scaleInput.backgroundColor  = CLR_BG;
    self.scaleInput.textColor        = CLR_ACCENT;
    self.scaleInput.textAlignment    = NSTextAlignmentCenter;
    self.scaleInput.keyboardType     = UIKeyboardTypeDecimalPad;
    self.scaleInput.layer.cornerRadius = 6;
    self.scaleInput.layer.borderWidth  = 0.5;
    self.scaleInput.layer.borderColor  = CLR_ACCENT.CGColor;
    // FIX: Dùng safeDefaultScale() thay vì [UIScreen mainScreen].scale (tránh infinite loop)
    CGFloat currentScale = safeDefaultScale();
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", currentScale];
    [scaleRow addSubview:self.scaleInput];

    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    applyBtn.frame            = CGRectMake(188, 7, 62, 30);
    applyBtn.backgroundColor  = CLR_ACCENT;
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    [applyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    applyBtn.titleLabel.font  = [UIFont boldSystemFontOfSize:12];
    applyBtn.layer.cornerRadius = 6;
    [applyBtn addTarget:self
                 action:@selector(applyScale)
       forControlEvents:UIControlEventTouchUpInside];
    [scaleRow addSubview:applyBtn];

    [self.scrollView addSubview:scaleRow];
    yOffset += 52;

    // ── Switch Rows ──
    for (NSDictionary *dict in features) {
        UIView *row = [[UIView alloc] initWithFrame:CGRectMake(0, yOffset, 260, 44)];
        row.backgroundColor    = CLR_ROW;
        row.layer.cornerRadius = 8;

        UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 195, 44)];
        lbl.text      = dict[@"name"];
        lbl.textColor = CLR_TEXT;
        lbl.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        [row addSubview:lbl];

        UISwitch *sw = [[UISwitch alloc] init];
        sw.frame      = CGRectMake(206, 9, 50, 26);
        sw.transform  = CGAffineTransformMakeScale(0.8, 0.8);
        sw.onTintColor = CLR_ACCENT;
        sw.accessibilityIdentifier = dict[@"key"];
        sw.on = [prefs boolForKey:dict[@"key"]];
        [sw addTarget:self
               action:@selector(switchToggled:)
     forControlEvents:UIControlEventValueChanged];
        [row addSubview:sw];

        [self.scrollView addSubview:row];
        yOffset += 52;
    }

    // ── Cảnh báo ──
    UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, yOffset + 4, 260, 26)];
    warn.text          = @"⚠️ Khởi động lại game để áp dụng";
    warn.textColor     = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:1.0];
    warn.font          = [UIFont systemFontOfSize:11];
    warn.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:warn];

    self.scrollView.contentSize = CGSizeMake(260, yOffset + 36);
}

// ── ACTIONS ──
- (void)toggleMenu {
    [self endEditing:YES];
    BOOL willShow = self.menuPanel.hidden;
    if (willShow) {
        self.menuPanel.alpha  = 0;
        self.menuPanel.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.menuPanel.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{
            self.menuPanel.alpha = 0;
        } completion:^(BOOL _) {
            self.menuPanel.hidden = YES;
        }];
    }
}

- (void)applyScale {
    [self endEditing:YES];
    float val = [self.scaleInput.text floatValue];
    if (val < 0.1f) val = 0.1f;
    if (val > 3.0f) val = 3.0f;
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", val];
    [GO_PREFS setFloat:val forKey:@"GO_Scale"];
}

- (void)switchToggled:(UISwitch *)sender {
    [GO_PREFS setBool:sender.isOn forKey:sender.accessibilityIdentifier];
}

// ── KÉO THẢ ──
- (void)panButton:(UIPanGestureRecognizer *)r {
    CGPoint p = [r translationInView:self];
    CGPoint newCenter = CGPointMake(self.floatingBtn.center.x + p.x,
                                    self.floatingBtn.center.y + p.y);
    // Giữ trong bounds màn hình
    CGFloat halfW = self.floatingBtn.frame.size.width  / 2;
    CGFloat halfH = self.floatingBtn.frame.size.height / 2;
    newCenter.x = MAX(halfW, MIN(self.frame.size.width  - halfW, newCenter.x));
    newCenter.y = MAX(halfH, MIN(self.frame.size.height - halfH, newCenter.y));
    self.floatingBtn.center = newCenter;
    [r setTranslation:CGPointZero inView:self];
}

- (void)panMenu:(UIPanGestureRecognizer *)r {
    CGPoint p = [r translationInView:self];
    self.menuPanel.center = CGPointMake(self.menuPanel.center.x + p.x,
                                         self.menuPanel.center.y + p.y);
    [r setTranslation:CGPointZero inView:self];
}

@end

// ═══════════════════════════════════════════════
// INJECTION
// ═══════════════════════════════════════════════
static GOMenuWindow *mainWindow;

__attribute__((constructor)) static void go_init() {
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
                mainWindow = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                if (scene) mainWindow.windowScene = scene;
                mainWindow.hidden = NO;
            });
        }];
    }
}