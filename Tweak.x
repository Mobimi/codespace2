#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

// =====================================================
// KÉT SẮT LƯU TRỮ (FULL 4 CHỨC NĂNG)
// =====================================================
static CGFloat go_scale = 3.0;
static BOOL go_thermalBypass = NO;
static BOOL go_antiMemKill = NO;
static BOOL go_backgroundAFK = NO;

static void LoadSettings() {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults objectForKey:@"GO_Scale"]) {
        go_scale = [defaults floatForKey:@"GO_Scale"];
    } else {
        go_scale = [UIScreen mainScreen].scale;
    }
    go_thermalBypass = [defaults boolForKey:@"GO_ThermalBypass"];
    go_antiMemKill = [defaults boolForKey:@"GO_AntiMemKill"];
    go_backgroundAFK = [defaults boolForKey:@"GO_BackgroundAFK"];
}

#define SAVE_FLOAT(key, val) [[NSUserDefaults standardUserDefaults] setFloat:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]
#define SAVE_BOOL(key, val) [[NSUserDefaults standardUserDefaults] setBool:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]

// =====================================================
// GIAO DIỆN MENU (Nút Tên Lửa 🚀)
// =====================================================
@interface FullMenuWindow : UIWindow
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UILabel *scaleLabel;
@end

@implementation FullMenuWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 200.0;
        self.backgroundColor = [UIColor clearColor];
        
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(20, 100, 45, 45);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 22.5;
        self.floatingBtn.layer.borderWidth = 1.5;
        self.floatingBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [self.floatingBtn setTitle:@"🚀" forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont systemFontOfSize:20];
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingBtn addGestureRecognizer:pan];
        [self addSubview:self.floatingBtn];
        
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 320)];
        self.menuView.center = self.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.layer.borderWidth = 1;
        self.menuView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.menuView.hidden = YES;
        [self addSubview:self.menuView];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 30)];
        title.text = @"GAME OPTIMIZER MAX";
        title.textColor = [UIColor greenColor];
        title.font = [UIFont boldSystemFontOfSize:18];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];
        
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        closeBtn.frame = CGRectMake(220, 10, 30, 30);
        [closeBtn setTitle:@"X" forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:18];
        [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.menuView addSubview:closeBtn];
        
        UILabel *scTitle = [[UILabel alloc] initWithFrame:CGRectMake(15, 50, 150, 20)];
        scTitle.text = @"Độ Phân Giải GPU";
        scTitle.textColor = [UIColor whiteColor];
        scTitle.font = [UIFont systemFontOfSize:13];
        [self.menuView addSubview:scTitle];
        
        self.scaleLabel = [[UILabel alloc] initWithFrame:CGRectMake(180, 50, 60, 20)];
        self.scaleLabel.text = [NSString stringWithFormat:@"%.1fx", go_scale];
        self.scaleLabel.textColor = [UIColor orangeColor];
        self.scaleLabel.font = [UIFont boldSystemFontOfSize:13];
        self.scaleLabel.textAlignment = NSTextAlignmentRight;
        [self.menuView addSubview:self.scaleLabel];
        
        UISlider *scaleSlider = [[UISlider alloc] initWithFrame:CGRectMake(15, 75, 230, 30)];
        scaleSlider.minimumValue = 1.0;
        scaleSlider.maximumValue = 3.0;
        scaleSlider.value = go_scale;
        [scaleSlider addTarget:self action:@selector(scaleChanged:) forControlEvents:UIControlEventValueChanged];
        [self.menuView addSubview:scaleSlider];
        
        UILabel *scNote = [[UILabel alloc] initWithFrame:CGRectMake(15, 105, 230, 15)];
        scNote.text = @"*Khởi động lại game để áp dụng";
        scNote.textColor = [UIColor grayColor];
        scNote.font = [UIFont systemFontOfSize:10];
        [self.menuView addSubview:scNote];
        
        [self createSwitchWithY:135 title:@"Đóng Băng Cảm Biến Nhiệt" state:go_thermalBypass action:@selector(thermalChanged:)];
        [self createSwitchWithY:185 title:@"Khiên Chống Văng RAM" state:go_antiMemKill action:@selector(memChanged:)];
        [self createSwitchWithY:235 title:@"Chạy Ngầm Bất Tử (AFK)" state:go_backgroundAFK action:@selector(afkChanged:)];
        
        UILabel *warning = [[UILabel alloc] initWithFrame:CGRectMake(10, 285, 240, 30)];
        warning.text = @"⚠️ Bật Đóng Băng Nhiệt bắt buộc xài sò lạnh!";
        warning.textColor = [UIColor redColor];
        warning.font = [UIFont boldSystemFontOfSize:10];
        warning.textAlignment = NSTextAlignmentCenter;
        warning.numberOfLines = 2;
        [self.menuView addSubview:warning];
    }
    return self;
}

- (void)createSwitchWithY:(CGFloat)y title:(NSString*)title state:(BOOL)state action:(SEL)action {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(15, y + 5, 180, 20)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont boldSystemFontOfSize:13];
    [self.menuView addSubview:lbl];
    
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(195, y, 50, 30)];
    sw.on = state;
    sw.onTintColor = [UIColor greenColor];
    [sw addTarget:self action:action forControlEvents:UIControlEventValueChanged];
    [self.menuView addSubview:sw];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point)) return YES;
    if (!self.menuView.hidden && CGRectContainsPoint(self.menuView.frame, point)) return YES;
    return NO;
}

- (void)toggleMenu {
    self.menuView.hidden = !self.menuView.hidden;
}

static CGPoint startCenter;
static CGPoint startTouch;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        startCenter = self.floatingBtn.center;
        startTouch = [recognizer locationInView:self];
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint currentTouch = [recognizer locationInView:self];
        self.floatingBtn.center = CGPointMake(startCenter.x + (currentTouch.x - startTouch.x), startCenter.y + (currentTouch.y - startTouch.y));
    }
}

- (void)scaleChanged:(UISlider *)sender {
    float val = round(sender.value * 2.0) / 2.0; 
    sender.value = val;
    self.scaleLabel.text = [NSString stringWithFormat:@"%.1fx", val];
    go_scale = val;
    SAVE_FLOAT(@"GO_Scale", val);
}
- (void)thermalChanged:(UISwitch *)sender { go_thermalBypass = sender.on; SAVE_BOOL(@"GO_ThermalBypass", sender.on); }
- (void)memChanged:(UISwitch *)sender { go_antiMemKill = sender.on; SAVE_BOOL(@"GO_AntiMemKill", sender.on); }
- (void)afkChanged:(UISwitch *)sender { go_backgroundAFK = sender.on; SAVE_BOOL(@"GO_BackgroundAFK", sender.on); }
@end

// =====================================================
// LÕI HOOKS (ĐỘ PHÂN GIẢI + 3 CHỨC NĂNG)
// =====================================================
%hook UIScreen
- (CGFloat)scale { return go_scale < 3.0 ? go_scale : %orig; }
- (CGFloat)nativeScale { return go_scale < 3.0 ? go_scale : %orig; }
%end
%hook UIWindow
- (void)setContentScaleFactor:(CGFloat)scale { %orig(go_scale < 3.0 ? go_scale : scale); }
%end
%hook UIView
- (void)setContentScaleFactor:(CGFloat)scale { %orig(go_scale < 3.0 ? go_scale : scale); }
%end
%hook CAMetalLayer
- (void)setContentsScale:(CGFloat)scale { %orig(go_scale < 3.0 ? go_scale : scale); }
%end
%hook CAEAGLLayer
- (void)setContentsScale:(CGFloat)scale { %orig(go_scale < 3.0 ? go_scale : scale); }
%end

%hook NSProcessInfo
- (NSProcessInfoThermalState)thermalState {
    if (go_thermalBypass) return NSProcessInfoThermalStateNominal; 
    return %orig;
}
%end

%hook UIApplication
- (void)didReceiveMemoryWarning {
    if (go_antiMemKill) return; 
    %orig;
}
- (void)_performMemoryWarning {
    if (go_antiMemKill) return; 
    %orig;
}
- (UIApplicationState)applicationState {
    if (go_backgroundAFK) return UIApplicationStateActive; 
    return %orig;
}
- (BOOL)_isSuspended {
    if (go_backgroundAFK) return NO;
    return %orig;
}
- (BOOL)_isBackground {
    if (go_backgroundAFK) return NO;
    return %orig;
}
%end

// =====================================================
// TIÊM MENU VÀO GAME
// =====================================================
static FullMenuWindow *fullWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            LoadSettings(); 
            fullWindow = [[FullMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            fullWindow.hidden = NO;
        });
    });
}
%end
