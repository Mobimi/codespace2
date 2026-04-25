#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>

// =====================================================
// KÉT SẮT LƯU TRỮ 
// =====================================================
static CGFloat go_scale = 3.0;

static void LoadSettings() {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"GO_Scale"]) {
        go_scale = [[NSUserDefaults standardUserDefaults] floatForKey:@"GO_Scale"];
    } else {
        go_scale = [UIScreen mainScreen].scale;
    }
}

#define SAVE_FLOAT(key, val) [[NSUserDefaults standardUserDefaults] setFloat:val forKey:key]; [[NSUserDefaults standardUserDefaults] synchronize]

// =====================================================
// GIAO DIỆN MENU (Tối giản, chỉ có Ô nhập Scale)
// =====================================================
@interface MinimalMenuWindow : UIWindow
@property (nonatomic, strong) UIButton *floatingBtn;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UITextField *scaleInput;
@end

@implementation MinimalMenuWindow
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.windowLevel = UIWindowLevelStatusBar + 200.0;
        self.backgroundColor = [UIColor clearColor];
        
        // Nút nổi 🚀
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
        
        // Bảng Menu Thu Gọn
        self.menuView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 170)];
        self.menuView.center = self.center;
        self.menuView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuView.layer.cornerRadius = 15;
        self.menuView.layer.borderWidth = 1;
        self.menuView.layer.borderColor = [UIColor darkGrayColor].CGColor;
        self.menuView.hidden = YES;
        
        // Chạm ra ngoài để ẩn bàn phím
        UITapGestureRecognizer *tapHide = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
        [self.menuView addGestureRecognizer:tapHide];
        [self addSubview:self.menuView];
        
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 25)];
        title.text = @"GAME OPTIMIZER";
        title.textColor = [UIColor cyanColor];
        title.font = [UIFont boldSystemFontOfSize:16];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:title];
        
        // Ghi chú về Scale mặc định
        UILabel *infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 240, 30)];
        infoLabel.text = @"Lưu ý: Scale mặc định của thiết bị/App thường là 3.0 (hoặc 2.0).";
        infoLabel.textColor = [UIColor lightGrayColor];
        infoLabel.font = [UIFont systemFontOfSize:10];
        infoLabel.textAlignment = NSTextAlignmentCenter;
        infoLabel.numberOfLines = 2;
        [self.menuView addSubview:infoLabel];
        
        // Ô nhập Scale
        self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(20, 80, 130, 35)];
        self.scaleInput.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.scaleInput.textColor = [UIColor yellowColor];
        self.scaleInput.font = [UIFont boldSystemFontOfSize:14];
        self.scaleInput.textAlignment = NSTextAlignmentCenter;
        self.scaleInput.keyboardType = UIKeyboardTypeDecimalPad;
        self.scaleInput.text = [NSString stringWithFormat:@"%.2f", go_scale];
        self.scaleInput.layer.cornerRadius = 8;
        // Thêm nút "Xong" trên bàn phím ảo
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Xong" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)];
        [toolbar setItems:@[flexSpace, doneBtn]];
        self.scaleInput.inputAccessoryView = toolbar;
        [self.menuView addSubview:self.scaleInput];
        
        // Nút Áp Dụng
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
        [self.menuView addSubview:applyBtn];
        
        UILabel *warnLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 125, 260, 20)];
        warnLabel.text = @"Khởi động lại Game để áp dụng!";
        warnLabel.textColor = [UIColor orangeColor];
        warnLabel.font = [UIFont boldSystemFontOfSize:11];
        warnLabel.textAlignment = NSTextAlignmentCenter;
        [self.menuView addSubview:warnLabel];
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point)) return YES;
    if (!self.menuView.hidden && CGRectContainsPoint(self.menuView.frame, point)) return YES;
    return NO;
}

- (void)toggleMenu { self.menuView.hidden = !self.menuView.hidden; }
- (void)hideKeyboard { [self.scaleInput resignFirstResponder]; }

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

- (void)applyScale {
    [self hideKeyboard];
    float val = [self.scaleInput.text floatValue];
    // Chặn ép xuống số 0 hoặc âm làm crash game
    if (val <= 0.1) val = 0.1; 
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", val];
    go_scale = val;
    SAVE_FLOAT(@"GO_Scale", val);
}
@end

// =====================================================
// LÕI HOOKS (CHẠY NGẦM 100%)
// =====================================================

// 1. MODULE ÉP ĐỘ PHÂN GIẢI
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

// 2. MODULE ĐÓNG BĂNG NHIỆT (Luôn bật ẩn)
%hook NSProcessInfo
- (NSProcessInfoThermalState)thermalState {
    return NSProcessInfoThermalStateNominal; // Luôn báo máy mát
}
%end

// 3. MODULE KHIÊN RAM (Luôn bật ẩn)
%hook UIApplication
- (void)didReceiveMemoryWarning { return; } // Chặn cảnh báo RAM
- (void)_performMemoryWarning { return; }
%end

// =====================================================
// TIÊM MENU VÀO GAME
// =====================================================
static MinimalMenuWindow *minWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            LoadSettings(); 
            minWindow = [[MinimalMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            minWindow.hidden = NO;
        });
    });
}
%end
