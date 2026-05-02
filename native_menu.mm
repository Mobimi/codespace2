#import <UIKit/UIKit.h>
#import <mach/mach.h>

// ═══════════════════════════════════════════════
//   UNIVERSAL OPTIMIZER — NATIVE UI MENU v4.0
//   Sidebar layout, tabs, clean RAM, auto clean
// ═══════════════════════════════════════════════

#define GO_SUITE  @"com.universal.optimizer"
#define GO_PREFS  [[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]
extern void updateGlobalScale(CGFloat newScale);

// Bảng màu
#define CLR_BG        [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.97]
#define CLR_SIDEBAR   [UIColor colorWithRed:0.06 green:0.07 blue:0.10 alpha:1.00]
#define CLR_ROW       [UIColor colorWithRed:0.12 green:0.14 blue:0.18 alpha:1.00]
#define CLR_ACCENT    [UIColor colorWithRed:0.00 green:0.85 blue:1.00 alpha:1.00]
#define CLR_TEXT      [UIColor colorWithWhite:0.95 alpha:1.00]
#define CLR_SUBTEXT   [UIColor colorWithWhite:0.55 alpha:1.00]
#define CLR_SELECTED  [UIColor colorWithRed:0.00 green:0.85 blue:1.00 alpha:0.15]

// Kích thước panel
#define PANEL_W   340.0f
#define PANEL_H   380.0f
#define SIDEBAR_W  82.0f
#define HEADER_H   40.0f
#define CONTENT_X  (SIDEBAR_W + 1)
#define CONTENT_W  (PANEL_W - CONTENT_X)

static CGFloat safeDefaultScale() {
    float saved = [GO_PREFS floatForKey:@"GO_Scale"];
    return (saved > 0.1f) ? (CGFloat)saved : [UIScreen mainScreen].nativeScale;
}

// ─── Auto Clean Timer ───────────────────────
static NSTimer *autoCleanTimer = nil;

static void startAutoClean(NSInteger thresholdMB) {
    [autoCleanTimer invalidate];
    autoCleanTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                     repeats:YES
                                                       block:^(NSTimer *t) {
        BOOL enabled = [GO_PREFS boolForKey:@"GO_AutoClean"];
        if (!enabled) { [t invalidate]; autoCleanTimer = nil; return; }
        // Kiểm tra RAM còn trống
        vm_statistics64_data_t vmStats;
        mach_msg_type_number_t infoCount = HOST_VM_INFO64_COUNT;
        if (host_statistics64(mach_host_self(), HOST_VM_INFO64,
                              (host_info64_t)&vmStats, &infoCount) == KERN_SUCCESS) {
            NSInteger freeMB = (vmStats.free_count * vm_page_size) / (1024 * 1024);
            if (freeMB < thresholdMB) {
                [[NSURLCache sharedURLCache] removeAllCachedResponses];
                [[NSURLCache sharedURLCache] setMemoryCapacity:0];
            }
        }
    }];
}

// ═══════════════════════════════════════════════
@interface GOMenuViewController : UIViewController
@end
@implementation GOMenuViewController
- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [UIApplication sharedApplication].keyWindow.rootViewController.supportedInterfaceOrientations;
}
- (BOOL)prefersStatusBarHidden { return YES; }
@end

// ═══════════════════════════════════════════════
@interface GOMenuWindow : UIWindow
@property (nonatomic, strong) UIButton     *floatingBtn;
@property (nonatomic, strong) UIView       *menuPanel;
@property (nonatomic, strong) UIView       *sidebar;
@property (nonatomic, strong) UIScrollView *contentScroll;
@property (nonatomic, strong) UITextField  *scaleInput;
@property (nonatomic, strong) UITextField  *autoCleanInput;
@property (nonatomic, assign) NSInteger     currentTab; // 0=Graphics 1=CPU 2=Memory 3=Info
@property (nonatomic, strong) NSArray      *tabButtons;
@end

@implementation GOMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.windowLevel     = UIWindowLevelStatusBar + 100;
    self.backgroundColor = [UIColor clearColor];
    self.rootViewController = [[GOMenuViewController alloc] init];
    self.currentTab = 0;
    [self setupFloatingButton];
    [self setupMenuPanel];
    return self;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point))
        return self.floatingBtn;
    if (!self.menuPanel.hidden && CGRectContainsPoint(self.menuPanel.frame, point))
        return [self.menuPanel hitTest:[self convertPoint:point toView:self.menuPanel] withEvent:event];
    return nil;
}

// ── NÚT FLOATING ──
- (void)setupFloatingButton {
    self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingBtn.frame = CGRectMake(20, 100, 46, 46);
    self.floatingBtn.backgroundColor    = CLR_BG;
    self.floatingBtn.layer.cornerRadius = 23;
    self.floatingBtn.layer.borderWidth  = 1.5;
    self.floatingBtn.layer.borderColor  = CLR_ACCENT.CGColor;
    self.floatingBtn.layer.shadowColor  = CLR_ACCENT.CGColor;
    self.floatingBtn.layer.shadowOffset = CGSizeZero;
    self.floatingBtn.layer.shadowRadius = 5;
    self.floatingBtn.layer.shadowOpacity = 0.45;
    [self.floatingBtn setTitle:@"⚙️" forState:UIControlStateNormal];
    [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panButton:)];
    [self.floatingBtn addGestureRecognizer:pan];
    [self addSubview:self.floatingBtn];
}

// ── PANEL CHÍNH ──
- (void)setupMenuPanel {
    self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PANEL_W, PANEL_H)];
    self.menuPanel.center           = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    self.menuPanel.backgroundColor  = CLR_BG;
    self.menuPanel.layer.cornerRadius  = 14;
    self.menuPanel.layer.masksToBounds = YES;
    self.menuPanel.layer.borderWidth   = 1.5;
    self.menuPanel.layer.borderColor   = CLR_ACCENT.CGColor;
    self.menuPanel.hidden = YES;

    // Shadow — view ngoài vì masksToBounds
    self.menuPanel.layer.shadowColor   = [UIColor blackColor].CGColor;
    self.menuPanel.layer.shadowOffset  = CGSizeMake(0, 4);
    self.menuPanel.layer.shadowRadius  = 12;
    self.menuPanel.layer.shadowOpacity = 0.0; // tắt vì masksToBounds

    // Header
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, PANEL_W, HEADER_H)];
    header.backgroundColor = CLR_SIDEBAR;
    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, PANEL_W - 36, HEADER_H)];
    titleLbl.text          = @"  ✦ UNIVERSAL OPTIMIZER";
    titleLbl.textColor     = CLR_ACCENT;
    titleLbl.font          = [UIFont boldSystemFontOfSize:12];
    [header addSubview:titleLbl];
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(PANEL_W - 34, 6, 28, 28);
    [closeBtn setTitle:@"✖" forState:UIControlStateNormal];
    [closeBtn setTitleColor:CLR_SUBTEXT forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [header addSubview:closeBtn];
    [self.menuPanel addSubview:header];

    // Separator header
    UIView *hSep = [[UIView alloc] initWithFrame:CGRectMake(0, HEADER_H, PANEL_W, 0.5)];
    hSep.backgroundColor = CLR_ACCENT;
    hSep.alpha = 0.3;
    [self.menuPanel addSubview:hSep];

    // Sidebar
    self.sidebar = [[UIView alloc] initWithFrame:CGRectMake(0, HEADER_H + 1, SIDEBAR_W, PANEL_H - HEADER_H - 1)];
    self.sidebar.backgroundColor = CLR_SIDEBAR;
    [self.menuPanel addSubview:self.sidebar];

    // Sidebar separator
    UIView *vSep = [[UIView alloc] initWithFrame:CGRectMake(SIDEBAR_W, HEADER_H + 1, 0.5, PANEL_H - HEADER_H - 1)];
    vSep.backgroundColor = CLR_ACCENT;
    vSep.alpha = 0.3;
    [self.menuPanel addSubview:vSep];

    // Tab buttons
    NSArray *tabs = @[
        @{@"icon": @"🎨", @"name": @"Graphics"},
        @{@"icon": @"⚡", @"name": @"CPU"},
        @{@"icon": @"💾", @"name": @"Memory"},
        @{@"icon": @"🎮", @"name": @"Roblox"},
        @{@"icon": @"📋", @"name": @"Info"},

    ];
    NSMutableArray *btns = [NSMutableArray array];
    for (NSInteger i = 0; i < tabs.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(4, HEADER_H + 1 + (i * 67), SIDEBAR_W - 8, 63);
        btn.backgroundColor    = (i == 0) ? CLR_SELECTED : [UIColor clearColor];
        btn.layer.cornerRadius = 8;
        btn.tag = i;
        UILabel *iconLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, SIDEBAR_W - 8, 22)];
        iconLbl.text          = tabs[i][@"icon"];
        iconLbl.font          = [UIFont systemFontOfSize:18];
        iconLbl.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:iconLbl];
        UILabel *nameLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, SIDEBAR_W - 8, 16)];
        nameLbl.text          = tabs[i][@"name"];
        nameLbl.font          = [UIFont systemFontOfSize:9];
        nameLbl.textColor     = (i == 0) ? CLR_ACCENT : CLR_SUBTEXT;
        nameLbl.textAlignment = NSTextAlignmentCenter;
        [btn addSubview:nameLbl];
        [btn addTarget:self action:@selector(tabTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.sidebar addSubview:btn];
        [btns addObject:btn];
    }
    self.tabButtons = btns;

    // Content scroll
    self.contentScroll = [[UIScrollView alloc] initWithFrame:CGRectMake(CONTENT_X + 1, HEADER_H + 1, CONTENT_W - 1, PANEL_H - HEADER_H - 1)];
    self.contentScroll.showsVerticalScrollIndicator = YES;
    self.contentScroll.alwaysBounceVertical = YES;
    self.contentScroll.backgroundColor = CLR_BG;
    [self.menuPanel addSubview:self.contentScroll];

    [self loadTabContent:0];

    // Pan kéo menu
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panMenu:)];
    [pan requireGestureRecognizerToFail:self.contentScroll.panGestureRecognizer];
    [self.menuPanel addGestureRecognizer:pan];

    [self addSubview:self.menuPanel];
}

// ── SWITCH TAB ──
- (void)tabTapped:(UIButton *)sender {
    self.currentTab = sender.tag;
    for (UIButton *btn in self.tabButtons) {
        btn.backgroundColor = (btn.tag == self.currentTab) ? CLR_SELECTED : [UIColor clearColor];
        UILabel *nameLbl = btn.subviews.lastObject;
        if ([nameLbl isKindOfClass:[UILabel class]])
            nameLbl.textColor = (btn.tag == self.currentTab) ? CLR_ACCENT : CLR_SUBTEXT;
    }
    // Xoá content cũ
    for (UIView *v in self.contentScroll.subviews) [v removeFromSuperview];
    [self loadTabContent:self.currentTab];
}

- (void)loadTabContent:(NSInteger)tab {
    CGFloat W = CONTENT_W - 16; // padding 8 mỗi bên
    CGFloat y = 8;

    if (tab == 0) { // ── GRAPHICS ──
        y = [self addSectionLabel:@"RENDER" y:y width:W];
        y = [self addSwitch:@"🎨  Render Optimize" key:@"GO_RenderOpt" y:y width:W];
        y = [self addSwitch:@"🔍  Anti-Blur GPU"   key:@"GO_AntiBlur"  y:y width:W];
        y = [self addSwitch:@"🎯  Disable MSAA"    key:@"GO_MSAADisable" y:y width:W];
        y = [self addSwitch:@"✂️  Anim Killer"     key:@"GO_AnimKiller" y:y width:W];
        y += 6;
        y = [self addSectionLabel:@"SCALE" y:y width:W];
        y = [self addScaleRow:y width:W];
        y += 6;
        y = [self addSectionLabel:@"DRAWABLE" y:y width:W];
        y = [self addDrawableRow:y width:W];

    } else if (tab == 1) { // ── CPU ──
        y = [self addSectionLabel:@"PERFORMANCE" y:y width:W];
        y = [self addSwitch:@"⚡  CPU Priority Boost" key:@"GO_CPUPriority"   y:y width:W];
        y = [self addSwitch:@"🎯  Input Lag Reduce"   key:@"GO_InputLag"      y:y width:W];
        y = [self addSwitch:@"🌡  Anti-Throttling"    key:@"GO_ThermalBypass" y:y width:W];
        y += 6;
        y = [self addSectionLabel:@"NETWORK" y:y width:W];
        y = [self addSwitch:@"🛡  Block Analytics"   key:@"GO_AnalyticsBlocker" y:y width:W];

    } else if (tab == 2) { // ── MEMORY ──
        y = [self addSectionLabel:@"AUTO CLEAN" y:y width:W];
        y = [self addSwitch:@"💾  RAM Warn Bypass" key:@"GO_RAMBypass" y:y width:W];
        y = [self addAutoCleanRow:y width:W];
        y += 6;
        y = [self addSectionLabel:@"MANUAL CLEAN" y:y width:W];
        y = [self addCleanButtons:y width:W];

    } else if (tab == 3) { // ── ROBLOX ──
        y = [self addSectionLabel:@"ROBLOX OPTIMIZE" y:y width:W];
        y = [self addSwitch:@"✨  Tắt Post-Processing" key:@"GO_RobloxPostFX"    y:y width:W];
        y = [self addSwitch:@"🛡  Chặn Telemetry"     key:@"GO_RobloxTelemetry" y:y width:W];
        y = [self addSwitch:@"🖼  Giảm Texture"        key:@"GO_RobloxLowTex"   y:y width:W];

    } else if (tab == 4) { // ── INFO ──
        y = [self addSectionLabel:@"HƯỚNG DẪN" y:y width:W];
        NSArray *notes = @[
            @"🎨 Render Optimize: Tối ưu pipeline Metal/OpenGL. Tắt nếu game bị lỗi đồ hoạ.",
            @"🎯 Disable MSAA: Tắt khử răng cưa, FPS tăng rõ, hình hơi cứng.",
            @"⚡ CPU Priority: Boost luồng chính lên mức cao nhất.",
            @"🎯 Input Lag: Giảm drawable count → phản hồi cảm ứng nhanh hơn.",
            @"🌡 Anti-Throttling: Ép nhiệt độ báo Nominal. Dùng lâu chip nóng.",
            @"💾 RAM Bypass: Chặn cảnh báo RAM, dọn cache thay thế.",
            @"🧹 Clean Light: Dọn cache mạng, không ảnh hưởng FPS.",
            @"🧹 Clean Deep: Dọn sâu, FPS drop ngắn rồi bình thường.",
            @"Scale: Nhập giá trị rồi bấm Apply. Khởi động lại để áp dụng.",
        ];
        for (NSString *note in notes) {
            y = [self addNoteRow:note y:y width:W];
        }
    }

    // Warning
    if (tab != 4) {
        UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, y + 6, W, 20)];
        warn.text          = @"⚠️ Khởi động lại game để áp dụng";
        warn.textColor     = [UIColor colorWithRed:1.0 green:0.8 blue:0.2 alpha:0.8];
        warn.font          = [UIFont systemFontOfSize:10];
        warn.textAlignment = NSTextAlignmentCenter;
        [self.contentScroll addSubview:warn];
        y += 28;
    }

    self.contentScroll.contentSize = CGSizeMake(W, y + 8);
}

// ── HELPERS TẠO ROW ──
- (CGFloat)addSectionLabel:(NSString *)text y:(CGFloat)y width:(CGFloat)W {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(8, y, W - 8, 16)];
    lbl.text      = text;
    lbl.textColor = CLR_ACCENT;
    lbl.font      = [UIFont boldSystemFontOfSize:9];
    lbl.alpha     = 0.7;
    [self.contentScroll addSubview:lbl];
    return y + 20;
}

- (CGFloat)addSwitch:(NSString *)name key:(NSString *)key y:(CGFloat)y width:(CGFloat)W {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, 38)];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, W - 70, 38)];
    lbl.text      = name;
    lbl.textColor = CLR_TEXT;
    lbl.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [row addSubview:lbl];
    UISwitch *sw = [[UISwitch alloc] init];
    sw.frame      = CGRectMake(W - 68, 6, 50, 26);
    sw.transform  = CGAffineTransformMakeScale(0.75, 0.75);
    sw.onTintColor = CLR_ACCENT;
    sw.accessibilityIdentifier = key;
    sw.on = [GO_PREFS boolForKey:key];
    [sw addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    [self.contentScroll addSubview:row];
    return y + 44;
}

- (CGFloat)addScaleRow:(CGFloat)y width:(CGFloat)W {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, 38)];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 45, 38)];
    lbl.text      = @"Scale";
    lbl.textColor = CLR_TEXT;
    lbl.font      = [UIFont systemFontOfSize:12];
    [row addSubview:lbl];
    self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(58, 5, 90, 28)];
    self.scaleInput.backgroundColor  = CLR_BG;
    self.scaleInput.textColor        = CLR_ACCENT;
    self.scaleInput.textAlignment    = NSTextAlignmentCenter;
    self.scaleInput.keyboardType     = UIKeyboardTypeDecimalPad;
    self.scaleInput.layer.cornerRadius = 6;
    self.scaleInput.layer.borderWidth  = 0.5;
    self.scaleInput.layer.borderColor  = CLR_ACCENT.CGColor;
    self.scaleInput.font = [UIFont systemFontOfSize:12];
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", safeDefaultScale()];
    [row addSubview:self.scaleInput];
    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    applyBtn.frame           = CGRectMake(W - 68, 5, 56, 28);
    applyBtn.backgroundColor = CLR_ACCENT;
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    [applyBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    applyBtn.titleLabel.font  = [UIFont boldSystemFontOfSize:11];
    applyBtn.layer.cornerRadius = 6;
    [applyBtn addTarget:self action:@selector(applyScale) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:applyBtn];
    [self.contentScroll addSubview:row];
    return y + 44;
}

- (CGFloat)addDrawableRow:(CGFloat)y width:(CGFloat)W {
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, 38)];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 38)];
    lbl.text      = @"🎮 Drawable";
    lbl.textColor = CLR_TEXT;
    lbl.font      = [UIFont systemFontOfSize:12];
    [row addSubview:lbl];
    UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:@[@"2", @"3"]];
    seg.frame    = CGRectMake(W - 98, 6, 86, 26);
    seg.tintColor = CLR_ACCENT;
    NSInteger saved = [GO_PREFS integerForKey:@"GO_DrawableCount"];
    seg.selectedSegmentIndex = (saved == 3) ? 1 : 0;
    [seg addTarget:self action:@selector(drawableChanged:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:seg];
    [self.contentScroll addSubview:row];
    return y + 44;
}

- (CGFloat)addAutoCleanRow:(CGFloat)y width:(CGFloat)W {
    // Switch Auto Clean
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, 38)];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, W - 70, 38)];
    lbl.text      = @"🤖  Auto Clean RAM";
    lbl.textColor = CLR_TEXT;
    lbl.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    [row addSubview:lbl];
    UISwitch *sw = [[UISwitch alloc] init];
    sw.frame      = CGRectMake(W - 68, 6, 50, 26);
    sw.transform  = CGAffineTransformMakeScale(0.75, 0.75);
    sw.onTintColor = CLR_ACCENT;
    sw.accessibilityIdentifier = @"GO_AutoClean";
    sw.on = [GO_PREFS boolForKey:@"GO_AutoClean"];
    [sw addTarget:self action:@selector(autoCleanToggled:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];
    [self.contentScroll addSubview:row];
    y += 44;

    // Threshold input
    UIView *threshRow = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, 38)];
    threshRow.backgroundColor    = CLR_ROW;
    threshRow.layer.cornerRadius = 8;
    UILabel *threshLbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 130, 38)];
    threshLbl.text      = @"📊 Ngưỡng (MB)";
    threshLbl.textColor = CLR_TEXT;
    threshLbl.font      = [UIFont systemFontOfSize:12];
    [threshRow addSubview:threshLbl];
    self.autoCleanInput = [[UITextField alloc] initWithFrame:CGRectMake(W - 98, 5, 86, 28)];
    self.autoCleanInput.backgroundColor  = CLR_BG;
    self.autoCleanInput.textColor        = CLR_ACCENT;
    self.autoCleanInput.textAlignment    = NSTextAlignmentCenter;
    self.autoCleanInput.keyboardType     = UIKeyboardTypeNumberPad;
    self.autoCleanInput.layer.cornerRadius = 6;
    self.autoCleanInput.layer.borderWidth  = 0.5;
    self.autoCleanInput.layer.borderColor  = CLR_ACCENT.CGColor;
    self.autoCleanInput.font = [UIFont systemFontOfSize:12];
    NSInteger savedThresh = [GO_PREFS integerForKey:@"GO_AutoCleanThreshold"];
    self.autoCleanInput.text = [NSString stringWithFormat:@"%ld", (long)(savedThresh > 0 ? savedThresh : 150)];
    [threshRow addSubview:self.autoCleanInput];

    UIButton *setBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    // Không có set button riêng — lưu khi nhập xong (return)
    (void)setBtn;

    [self.contentScroll addSubview:threshRow];
    y += 44;
    return y;
}

- (CGFloat)addCleanButtons:(CGFloat)y width:(CGFloat)W {
    CGFloat btnW = (W - 28) / 2;
    // Light Clean
    UIButton *lightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    lightBtn.frame           = CGRectMake(8, y, btnW, 36);
    lightBtn.backgroundColor = CLR_ROW;
    [lightBtn setTitle:@"🧹 Light Clean" forState:UIControlStateNormal];
    [lightBtn setTitleColor:CLR_ACCENT forState:UIControlStateNormal];
    lightBtn.titleLabel.font  = [UIFont boldSystemFontOfSize:11];
    lightBtn.layer.cornerRadius = 8;
    lightBtn.layer.borderWidth  = 0.5;
    lightBtn.layer.borderColor  = CLR_ACCENT.CGColor;
    [lightBtn addTarget:self action:@selector(cleanLight) forControlEvents:UIControlEventTouchUpInside];
    [self.contentScroll addSubview:lightBtn];

    // Deep Clean
    UIButton *deepBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    deepBtn.frame           = CGRectMake(8 + btnW + 12, y, btnW, 36);
    deepBtn.backgroundColor = CLR_ROW;
    [deepBtn setTitle:@"🔥 Deep Clean" forState:UIControlStateNormal];
    [deepBtn setTitleColor:[UIColor colorWithRed:1.0 green:0.4 blue:0.3 alpha:1.0] forState:UIControlStateNormal];
    deepBtn.titleLabel.font  = [UIFont boldSystemFontOfSize:11];
    deepBtn.layer.cornerRadius = 8;
    deepBtn.layer.borderWidth  = 0.5;
    deepBtn.layer.borderColor  = [UIColor colorWithRed:1.0 green:0.4 blue:0.3 alpha:0.6].CGColor;
    [deepBtn addTarget:self action:@selector(cleanDeep) forControlEvents:UIControlEventTouchUpInside];
    [self.contentScroll addSubview:deepBtn];

    return y + 42;
}

- (CGFloat)addNoteRow:(NSString *)text y:(CGFloat)y width:(CGFloat)W {
    CGFloat h = 44;
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(8, y, W - 8, h)];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(10, 4, W - 28, h - 8)];
    lbl.text          = text;
    lbl.textColor     = CLR_SUBTEXT;
    lbl.font          = [UIFont systemFontOfSize:10];
    lbl.numberOfLines = 0;
    lbl.lineBreakMode = NSLineBreakByWordWrapping;
    // Resize height theo text
    CGSize size = [text boundingRectWithSize:CGSizeMake(W - 28, 200)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName: lbl.font}
                                     context:nil].size;
    h = size.height + 16;
    row.frame = CGRectMake(8, y, W - 8, h);
    lbl.frame = CGRectMake(10, 4, W - 28, h - 8);
    [row addSubview:lbl];
    [self.contentScroll addSubview:row];
    return y + h + 6;
}

// ── ACTIONS ──
- (void)toggleMenu {
    [self endEditing:YES];
    BOOL willShow = self.menuPanel.hidden;
    if (willShow) {
        self.menuPanel.alpha  = 0;
        self.menuPanel.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{ self.menuPanel.alpha = 1; }];
    } else {
        [UIView animateWithDuration:0.15 animations:^{ self.menuPanel.alpha = 0; }
                         completion:^(BOOL _) { self.menuPanel.hidden = YES; }];
    }
}

- (void)applyScale {
    [self endEditing:YES];
    float val = [self.scaleInput.text floatValue];
    if (val < 0.1f) val = 0.1f;
    if (val > 3.0f) val = 3.0f;
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", val];
    [GO_PREFS setFloat:val forKey:@"GO_Scale"];
    updateGlobalScale((CGFloat)val);
}

- (void)drawableChanged:(UISegmentedControl *)seg {
    [GO_PREFS setInteger:(seg.selectedSegmentIndex == 1) ? 3 : 2 forKey:@"GO_DrawableCount"];
}

- (void)switchToggled:(UISwitch *)sender {
    [GO_PREFS setBool:sender.isOn forKey:sender.accessibilityIdentifier];
}

- (void)autoCleanToggled:(UISwitch *)sender {
    [GO_PREFS setBool:sender.isOn forKey:@"GO_AutoClean"];
    if (sender.isOn) {
        NSInteger thresh = self.autoCleanInput ? [self.autoCleanInput.text integerValue] : 0;
        if (thresh <= 0) thresh = 150;
        [GO_PREFS setInteger:thresh forKey:@"GO_AutoCleanThreshold"];
        startAutoClean(thresh);
    } else {
        [autoCleanTimer invalidate];
        autoCleanTimer = nil;
    }
}

- (void)cleanLight {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
}

- (void)cleanDeep {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    [[UIApplication sharedApplication] performSelector:@selector(_performMemoryWarning)];
}

// ── KÉO THẢ ──
- (void)panButton:(UIPanGestureRecognizer *)r {
    CGPoint p = [r translationInView:self];
    CGPoint c = CGPointMake(self.floatingBtn.center.x + p.x, self.floatingBtn.center.y + p.y);
    CGFloat hw = self.floatingBtn.frame.size.width / 2, hh = self.floatingBtn.frame.size.height / 2;
    c.x = MAX(hw, MIN(self.bounds.size.width - hw, c.x));
    c.y = MAX(hh, MIN(self.bounds.size.height - hh, c.y));
    self.floatingBtn.center = c;
    [r setTranslation:CGPointZero inView:self];
}

- (void)panMenu:(UIPanGestureRecognizer *)r {
    CGPoint p = [r translationInView:self];
    CGPoint c = CGPointMake(self.menuPanel.center.x + p.x, self.menuPanel.center.y + p.y);
    CGFloat hw = self.menuPanel.frame.size.width / 2, hh = self.menuPanel.frame.size.height / 2;
    c.x = MAX(hw, MIN(self.frame.size.width - hw, c.x));
    c.y = MAX(hh, MIN(self.frame.size.height - hh, c.y));
    self.menuPanel.center = c;
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
        BOOL isUserApp = [path containsString:@"/Application/"] || [path containsString:@"/Containers/"];
        if (!isUserApp) return;

        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *n) {
            static dispatch_once_t once;
            dispatch_once(&once, ^{
                UIWindowScene *scene = nil;
                for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
                    if (s.activationState == UISceneActivationStateForegroundActive &&
                        [s isKindOfClass:[UIWindowScene class]]) { scene = (UIWindowScene *)s; break; }
                }
                mainWindow = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                if (scene) mainWindow.windowScene = scene;
                mainWindow.hidden = NO;

                // Khôi phục auto clean nếu đã bật trước đó
                if ([GO_PREFS boolForKey:@"GO_AutoClean"]) {
                    NSInteger thresh = [GO_PREFS integerForKey:@"GO_AutoCleanThreshold"];
                    startAutoClean(thresh > 0 ? thresh : 150);
                }
            });
        }];
    }
}