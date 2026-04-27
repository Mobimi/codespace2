#import <UIKit/UIKit.h>

// ═══════════════════════════════════════════════
//   UNIVERSAL OPTIMIZER — GUI v2.0
//   Auto Layout: Portrait ↕ / Landscape ↔
// ═══════════════════════════════════════════════

#define GO_SUITE  @"com.universal.optimizer"
#define GO_PREFS  [[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]

// Palette
#define CLR_BG     [UIColor colorWithRed:0.05 green:0.06 blue:0.12 alpha:0.97]
#define CLR_ROW    [UIColor colorWithRed:0.10 green:0.12 blue:0.20 alpha:1.00]
#define CLR_ACCENT [UIColor colorWithRed:0.00 green:0.85 blue:1.00 alpha:1.00]
#define CLR_GREEN  [UIColor colorWithRed:0.15 green:0.80 blue:0.45 alpha:1.00]
#define CLR_WARN   [UIColor colorWithRed:1.00 green:0.65 blue:0.00 alpha:1.00]
#define CLR_TEXT   [UIColor colorWithWhite:0.90 alpha:1.00]
#define CLR_DIM    [UIColor colorWithWhite:0.55 alpha:1.00]

// Danh sách switch
static NSArray *switchItems() {
    return @[
        @{@"t": @"CPU Priority Boost",  @"k": @"GO_CPUPriority",      @"i": @"⚡️"},
        @{@"t": @"Input Lag Reduce",    @"k": @"GO_InputLag",         @"i": @"🎯"},
        @{@"t": @"RAM Warn Bypass",     @"k": @"GO_RAMBypass",        @"i": @"💾"},
        @{@"t": @"Anti-Throttling",     @"k": @"GO_ThermalBypass",    @"i": @"🌡️"},
        @{@"t": @"UI Anim Killer",      @"k": @"GO_AnimKiller",       @"i": @"✂️"},
        @{@"t": @"Anti-Blur GPU",       @"k": @"GO_AntiBlur",         @"i": @"🔍"},
        @{@"t": @"Block Analytics",     @"k": @"GO_AnalyticsBlocker", @"i": @"🛡️"},
    ];
}

// ═══════════════════════════════════════════════
@interface GOMenuWindow : UIWindow
@property (nonatomic, strong) UIButton    *floatingBtn;
@property (nonatomic, strong) UIView      *menuPanel;
@property (nonatomic, strong) UITextField *scaleInput;
- (void)buildLayout;
@end

// ═══════════════════════════════════════════════
@interface GOMenuViewController : UIViewController
@end

@implementation GOMenuViewController
- (BOOL)shouldAutorotate { return YES; }
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    for (UIWindowScene *sc in [UIApplication sharedApplication].connectedScenes) {
        if (![sc isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *w in [(UIWindowScene *)sc windows]) {
            if ([w isKindOfClass:NSClassFromString(@"GOMenuWindow")]) continue;
            if (w.rootViewController)
                return [w.rootViewController supportedInterfaceOrientations];
        }
    }
    return UIInterfaceOrientationMaskAll;
}
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [UIApplication sharedApplication].statusBarOrientation;
}
- (BOOL)prefersStatusBarHidden { return YES; }
@end

// ═══════════════════════════════════════════════
@implementation GOMenuWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.windowLevel     = UIWindowLevelAlert + 1;
    self.backgroundColor = [UIColor clearColor];
    self.rootViewController = [[GOMenuViewController alloc] init];

    // ── Floating Button ──────────────────────────
    self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.floatingBtn.frame               = CGRectMake(16, 110, 46, 46);
    self.floatingBtn.backgroundColor     = CLR_BG;
    self.floatingBtn.layer.cornerRadius  = 23;
    self.floatingBtn.layer.borderWidth   = 1.6;
    self.floatingBtn.layer.borderColor   = CLR_ACCENT.CGColor;
    self.floatingBtn.layer.shadowColor   = CLR_ACCENT.CGColor;
    self.floatingBtn.layer.shadowRadius  = 7;
    self.floatingBtn.layer.shadowOpacity = 0.65;
    self.floatingBtn.layer.shadowOffset  = CGSizeMake(0, 0);
    [self.floatingBtn setTitle:@"⚙️" forState:UIControlStateNormal];
    self.floatingBtn.titleLabel.font = [UIFont systemFontOfSize:21];
    [self.floatingBtn addTarget:self action:@selector(toggleMenu)
               forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pb = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePanBtn:)];
    [self.floatingBtn addGestureRecognizer:pb];
    [self addSubview:self.floatingBtn];

    // ── Menu Panel ───────────────────────────────
    self.menuPanel = [[UIView alloc] initWithFrame:CGRectZero];
    self.menuPanel.backgroundColor     = CLR_BG;
    self.menuPanel.layer.cornerRadius  = 16;
    self.menuPanel.layer.borderWidth   = 1.2;
    self.menuPanel.layer.borderColor   = CLR_ACCENT.CGColor;
    self.menuPanel.layer.shadowColor   = CLR_ACCENT.CGColor;
    self.menuPanel.layer.shadowRadius  = 12;
    self.menuPanel.layer.shadowOpacity = 0.30;
    self.menuPanel.layer.shadowOffset  = CGSizeMake(0, 0);
    self.menuPanel.hidden = YES;
    [self addSubview:self.menuPanel];

    UIPanGestureRecognizer *pm = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePanMenu:)];
    [self.menuPanel addGestureRecognizer:pm];

    // Lắng nghe xoay màn hình
    [[NSNotificationCenter defaultCenter]
        addObserver:self
           selector:@selector(onRotate)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];

    return self;
}

// ═══════════════════════════════════════════════
#pragma mark - Orientation

- (BOOL)isLandscape {
    CGSize s = [UIScreen mainScreen].bounds.size;
    return s.width > s.height;
}

- (void)onRotate {
    if (!self.menuPanel.hidden) {
        [self buildLayout];
        CGSize s = [UIScreen mainScreen].bounds.size;
        self.menuPanel.center = CGPointMake(s.width / 2, s.height / 2);
    }
}

// ═══════════════════════════════════════════════
#pragma mark - Layout

- (void)buildLayout {
    for (UIView *v in self.menuPanel.subviews) [v removeFromSuperview];
    [self isLandscape] ? [self layoutLandscape] : [self layoutPortrait];
}

// PORTRAIT — 1 cột, 265 × dynamic
- (void)layoutPortrait {
    const CGFloat W = 265, ROW = 38, PAD = 12;
    NSArray *items = switchItems();
    CGFloat H = 44 + 44 + 6 + (ROW * items.count) + 8 + 32 + PAD;

    self.menuPanel.frame = CGRectMake(0, 0, W, H);
    CGSize sc = [UIScreen mainScreen].bounds.size;
    self.menuPanel.center = CGPointMake(sc.width / 2, sc.height / 2);

    CGFloat y = 0;
    [self.menuPanel addSubview:[self titleBarWidth:W height:36 y:y]];
    y += 40;

    [self.menuPanel addSubview:[self scaleRowFrame:CGRectMake(PAD, y, W - PAD*2, 36)]];
    y += 42;

    [self.menuPanel addSubview:[self dividerX:PAD y:y w:W - PAD*2]];
    y += 8;

    for (NSDictionary *item in items) {
        [self.menuPanel addSubview:[self switchRow:item frame:CGRectMake(PAD, y, W-PAD*2, ROW-2)]];
        y += ROW;
    }

    UILabel *warn = [self warnLabel:CGRectMake(PAD, y+4, W-PAD*2, 26)];
    [self.menuPanel addSubview:warn];
}

// LANDSCAPE — 2 cột, 480 × 205
- (void)layoutLandscape {
    const CGFloat W = 480, H = 205, PAD = 12;
    const CGFloat COL = (W - PAD * 3) / 2;

    self.menuPanel.frame = CGRectMake(0, 0, W, H);
    CGSize sc = [UIScreen mainScreen].bounds.size;
    self.menuPanel.center = CGPointMake(sc.width / 2, sc.height / 2);

    CGFloat y = 0;
    [self.menuPanel addSubview:[self titleBarWidth:W height:30 y:y]];
    y += 33;
    [self.menuPanel addSubview:[self dividerX:PAD y:y w:W - PAD*2]];
    y += 6;

    // Cột trái: Scale + 4 switch
    CGFloat lx = PAD, ly = y;
    [self.menuPanel addSubview:[self scaleRowFrame:CGRectMake(lx, ly, COL, 32)]];
    ly += 36;
    NSArray *items = switchItems();
    for (int i = 0; i < 4; i++) {
        [self.menuPanel addSubview:[self switchRow:items[i] frame:CGRectMake(lx, ly, COL, 32)]];
        ly += 35;
    }

    // Divider dọc giữa
    UIView *vd = [[UIView alloc] initWithFrame:CGRectMake(W/2, y-2, 1, H - y + 2)];
    vd.backgroundColor = [UIColor colorWithRed:0 green:0.85 blue:1 alpha:0.2];
    [self.menuPanel addSubview:vd];

    // Cột phải: 3 switch + warning
    CGFloat rx = W/2 + PAD, ry = y;
    for (int i = 4; i < 7; i++) {
        [self.menuPanel addSubview:[self switchRow:items[i] frame:CGRectMake(rx, ry, COL, 32)]];
        ry += 35;
    }
    [self.menuPanel addSubview:[self warnLabel:CGRectMake(rx, ry+4, COL, 28)]];
}

// ═══════════════════════════════════════════════
#pragma mark - UI Factories

- (UIView *)titleBarWidth:(CGFloat)w height:(CGFloat)h y:(CGFloat)y {
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, y, w, h)];
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    lbl.text          = @"✦  UNIVERSAL OPTIMIZER  ✦";
    lbl.textColor     = CLR_ACCENT;
    lbl.font          = [UIFont boldSystemFontOfSize:13];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.layer.shadowColor   = CLR_ACCENT.CGColor;
    lbl.layer.shadowRadius  = 5;
    lbl.layer.shadowOpacity = 0.85;
    lbl.layer.shadowOffset  = CGSizeMake(0, 0);
    [bar addSubview:lbl];
    return bar;
}

- (UIView *)dividerX:(CGFloat)x y:(CGFloat)y w:(CGFloat)w {
    UIView *d = [[UIView alloc] initWithFrame:CGRectMake(x, y, w, 1)];
    d.backgroundColor = [UIColor colorWithRed:0 green:0.85 blue:1 alpha:0.2];
    return d;
}

- (UIView *)scaleRowFrame:(CGRect)f {
    UIView *row = [[UIView alloc] initWithFrame:f];
    CGFloat h = f.size.height, w = f.size.width;

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 44, h)];
    lbl.text      = @"Scale";
    lbl.textColor = CLR_DIM;
    lbl.font      = [UIFont systemFontOfSize:11];
    [row addSubview:lbl];

    CGFloat tfW = w - 44 - 74;
    self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(44, 1, tfW, h-2)];
    self.scaleInput.backgroundColor  = CLR_ROW;
    self.scaleInput.textColor        = [UIColor colorWithRed:1.0 green:0.88 blue:0.2 alpha:1];
    self.scaleInput.textAlignment    = NSTextAlignmentCenter;
    self.scaleInput.keyboardType     = UIKeyboardTypeDecimalPad;
    self.scaleInput.layer.cornerRadius = 7;
    self.scaleInput.layer.borderWidth  = 0.8;
    self.scaleInput.layer.borderColor  = CLR_ACCENT.CGColor;
    self.scaleInput.font = [UIFont monospacedDigitSystemFontOfSize:13
                                                            weight:UIFontWeightMedium];
    float sv = [GO_PREFS floatForKey:@"GO_Scale"];
    if (sv <= 0.1) sv = [UIScreen mainScreen].scale;
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", sv];

    UIToolbar *tb = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    tb.barStyle = UIBarStyleBlack;
    UIBarButtonItem *flex = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithTitle:@"Xong" style:UIBarButtonItemStyleDone
               target:self action:@selector(hideKeyboard)];
    [tb setItems:@[flex, done]];
    self.scaleInput.inputAccessoryView = tb;
    [row addSubview:self.scaleInput];

    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(44 + tfW + 4, 1, 70, h-2);
    [btn setTitle:@"✔ Apply" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.titleLabel.font    = [UIFont boldSystemFontOfSize:11];
    btn.backgroundColor    = CLR_GREEN;
    btn.layer.cornerRadius = 7;
    [btn addTarget:self action:@selector(applyScale) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:btn];

    return row;
}

- (UIView *)switchRow:(NSDictionary *)d frame:(CGRect)f {
    UIView *row = [[UIView alloc] initWithFrame:f];
    row.backgroundColor    = CLR_ROW;
    row.layer.cornerRadius = 8;

    UILabel *icon = [[UILabel alloc] initWithFrame:CGRectMake(7, 0, 20, f.size.height)];
    icon.text = d[@"i"];
    icon.font = [UIFont systemFontOfSize:12];
    [row addSubview:icon];

    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(28, 0, f.size.width - 84, f.size.height)];
    lbl.text      = d[@"t"];
    lbl.textColor = CLR_TEXT;
    lbl.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
    lbl.adjustsFontSizeToFitWidth = YES;
    lbl.minimumScaleFactor = 0.75;
    [row addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] init];
    sw.transform = CGAffineTransformMakeScale(0.70, 0.70);
    CGFloat swW = sw.frame.size.width, swH = sw.frame.size.height;
    sw.frame = CGRectMake(f.size.width - swW - 4, (f.size.height - swH) / 2, swW, swH);
    sw.on          = [GO_PREFS boolForKey:d[@"k"]];
    sw.onTintColor = CLR_ACCENT;
    sw.accessibilityIdentifier = d[@"k"];
    [sw addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [row addSubview:sw];

    return row;
}

- (UILabel *)warnLabel:(CGRect)f {
    UILabel *w = [[UILabel alloc] initWithFrame:f];
    w.text          = @"⚠️  Restart game để có hiệu lực";
    w.textColor     = CLR_WARN;
    w.font          = [UIFont systemFontOfSize:10];
    w.textAlignment = NSTextAlignmentCenter;
    w.numberOfLines = 2;
    return w;
}

// ═══════════════════════════════════════════════
#pragma mark - Actions

- (void)toggleMenu {
    if (self.menuPanel.hidden) {
        [self buildLayout];
        CGSize s = [UIScreen mainScreen].bounds.size;
        self.menuPanel.center    = CGPointMake(s.width/2, s.height/2);
        self.menuPanel.hidden    = NO;
        self.menuPanel.alpha     = 0;
        self.menuPanel.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [UIView animateWithDuration:0.20 delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.menuPanel.alpha     = 1;
            self.menuPanel.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        [self hideKeyboard];
        [UIView animateWithDuration:0.15 animations:^{
            self.menuPanel.alpha     = 0;
            self.menuPanel.transform = CGAffineTransformMakeScale(0.85, 0.85);
        } completion:^(BOOL _) {
            self.menuPanel.hidden    = YES;
            self.menuPanel.alpha     = 1;
            self.menuPanel.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)hideKeyboard { [self.scaleInput resignFirstResponder]; }

- (void)applyScale {
    [self hideKeyboard];
    float v = [self.scaleInput.text floatValue];
    if (v < 0.1) v = 0.1;
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", v];
    [GO_PREFS setFloat:v forKey:@"GO_Scale"];
}

- (void)toggleSwitch:(UISwitch *)sw {
    [GO_PREFS setBool:sw.isOn forKey:sw.accessibilityIdentifier];
}

// ═══════════════════════════════════════════════
#pragma mark - Gesture

- (void)handlePanBtn:(UIPanGestureRecognizer *)r {
    CGPoint d = [r translationInView:self];
    self.floatingBtn.center = CGPointMake(self.floatingBtn.center.x + d.x,
                                          self.floatingBtn.center.y + d.y);
    [r setTranslation:CGPointZero inView:self];
}

- (void)handlePanMenu:(UIPanGestureRecognizer *)r {
    CGPoint d = [r translationInView:self];
    self.menuPanel.center = CGPointMake(self.menuPanel.center.x + d.x,
                                        self.menuPanel.center.y + d.y);
    [r setTranslation:CGPointZero inView:self];
}

// ═══════════════════════════════════════════════
#pragma mark - Hit Test

- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, p))
        return self.floatingBtn;
    if (!self.menuPanel.hidden && CGRectContainsPoint(self.menuPanel.frame, p))
        return [self.menuPanel hitTest:[self convertPoint:p toView:self.menuPanel] withEvent:e];
    return nil;
}

@end

// ═══════════════════════════════════════════════
static GOMenuWindow *goWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            goWindow = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            goWindow.windowScene = (UIWindowScene *)self;
            goWindow.hidden = NO;
        });
    });
}
%end
