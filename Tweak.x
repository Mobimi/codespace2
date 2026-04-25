#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

// --- KÉT SẮT LƯU TRỮ ---
static CGFloat go_scale = 3.0;

static void LoadSettings() {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"GO_Scale"]) {
        go_scale = [[NSUserDefaults standardUserDefaults] floatForKey:@"GO_Scale"];
    } else {
        go_scale = [UIScreen mainScreen].scale;
    }
}
#define SAVE_FLOAT(key, val) [[NSUserDefaults standardUserDefaults] setFloat:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]

// --- BỘ BẢO KÊ XOAY MÀN HÌNH (Chép bài Game) ---
@interface GORootVC : UIViewController
@end
@implementation GORootVC
- (BOOL)prefersStatusBarHidden { return YES; }
- (UIViewController *)gameRootVC {
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = (UIWindowScene *)self.view.window.windowScene;
        for (UIWindow *w in scene.windows) {
            if (w != self.view.window && w.isKeyWindow && w.rootViewController) {
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

// --- GIAO DIỆN GAME OPTIMIZER ---
@interface GOMenuWindow : UIWindow
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *menuPanel;
@property (nonatomic, strong) UITextField *scaleInput;
@end

@implementation GOMenuWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 200.0;
        self.backgroundColor = [UIColor clearColor]; 
        
        // Nút nổi
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(20, 100, 45, 45);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 22.5;
        self.floatingBtn.layer.borderWidth = 1.5;
        self.floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
        [self.floatingBtn setTitle:@"🚀" forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont systemFontOfSize:20];
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.floatingBtn addGestureRecognizer:pan];
        [self addSubview:self.floatingBtn];
        
        // Bảng Menu (Panel)
        self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 170)];
        self.menuPanel.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.menuPanel.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuPanel.layer.cornerRadius = 15;
        self.menuPanel.layer.borderWidth = 1;
        self.menuPanel.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.menuPanel.hidden = YES;
        
        UITapGestureRecognizer *tapHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
        [self.menuPanel addGestureRecognizer:tapHide];
        [self addSubview:self.menuPanel];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 25)];
        title.text = @"GAME OPTIMIZER";
        title.textColor = [UIColor cyanColor];
        title.font = [UIFont boldSystemFontOfSize:16];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:title];
        
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 240, 30)];
        infoLabel.text = @"Lưu ý: Scale mặc định thường là 3.0";
        infoLabel.textColor = [UIColor lightGrayColor];
        infoLabel.font = [UIFont systemFontOfSize:11];
        infoLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:infoLabel];
        
        self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(20, 80, 130, 35)];
        self.scaleInput.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.scaleInput.textColor = [UIColor yellowColor];
        self.scaleInput.font = [UIFont boldSystemFontOfSize:14];
        self.scaleInput.textAlignment = NSTextAlignmentCenter;
        self.scaleInput.keyboardType = UIKeyboardTypeDecimalPad;
        self.scaleInput.text = [NSString stringWithFormat:@"%.2f", go_scale];
        self.scaleInput.layer.cornerRadius = 8;
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Xong" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)];
        [toolbar setItems:@[flexSpace, doneBtn]];
        self.scaleInput.inputAccessoryView = toolbar;
        [self.menuPanel addSubview:self.scaleInput];
        
        UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        applyBtn.frame = CGRectMake(160, 80, 80, 35);
        applyBtn.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        applyBtn.layer.cornerRadius = 8;
        applyBtn.layer.borderWidth = 1;
        applyBtn.layer.borderColor = [UIColor greenColor].CGColor;
        [applyBtn setTitle:@"Áp Dụng" forState:UIControlStateNormal];
        [applyBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        applyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [applyBtn addTarget:self action:@selector(applyScale) forControlEvents:UIControlEventTouchUpInside];
        [self.menuPanel addSubview:applyBtn];
        
        UILabel *warnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 125, 260, 20)];
        warnLabel.text = @"Khởi động lại Game để áp dụng!";
        warnLabel.textColor = [UIColor orangeColor];
        warnLabel.font = [UIFont boldSystemFontOfSize:11];
        warnLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:warnLabel];
    }
    return self;
}

// FIX: Cảm ứng chỉ ăn vào nút hoặc menu, không bị lệch khi xoay
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden) {
        CGPoint pntBtn = [self convertPoint:point toView:self.floatingBtn];
        if ([self.floatingBtn pointInside:pntBtn withEvent:event]) return YES;
    }
    if (!self.menuPanel.hidden) {
        CGPoint pntPanel = [self convertPoint:point toView:self.menuPanel];
        if ([self.menuPanel pointInside:pntPanel withEvent:event]) return YES;
    }
    return NO;
}

- (void)toggleMenu { self.menuPanel.hidden = !self.menuPanel.hidden; }
- (void)hideKeyboard { [self.scaleInput resignFirstResponder]; }

// FIX KÉO THẢ MƯỢT
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self];
    self.floatingBtn.center = CGPointMake(self.floatingBtn.center.x + translation.x, self.floatingBtn.center.y + translation.y);
    [recognizer setTranslation:CGPointZero inView:self];
}

- (void)applyScale {
    [self hideKeyboard];
    float val = [self.scaleInput.text floatValue];
    if (val <= 0.1) val = 0.1; 
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", val];
    go_scale = val;
    SAVE_FLOAT(@"GO_Scale", val);
}

// Luôn giữ Menu ở giữa màn hình
- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.menuPanel.hidden) {
        self.menuPanel.center = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
}
@end

// --- LÕI HOOKS (CHẠY NGẦM) ---
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
- (NSProcessInfoThermalState)thermalState { return NSProcessInfoThermalStateNominal; }
%end
%hook UIApplication
- (void)didReceiveMemoryWarning { return; }
- (void)_performMemoryWarning { return; }
%end

// --- TIÊM VÀO GAME ---
static GOMenuWindow *goWindow;
%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            LoadSettings(); 
            goWindow = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            goWindow.windowScene = (UIWindowScene *)self;
            goWindow.rootViewController = [[GORootVC alloc] init];
            goWindow.hidden = NO;
        });
    });
}
%end
