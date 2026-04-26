#import <UIKit/UIKit.h>

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

        // 1. NÚT LƠ LỬNG
        self.floatingBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.floatingBtn.frame = CGRectMake(20, 100, 45, 45);
        self.floatingBtn.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.8];
        self.floatingBtn.layer.cornerRadius = 22.5;
        self.floatingBtn.layer.borderWidth = 1.5;
        self.floatingBtn.layer.borderColor = [UIColor cyanColor].CGColor;
        [self.floatingBtn setTitle:@"🚀" forState:UIControlStateNormal];
        self.floatingBtn.titleLabel.font = [UIFont systemFontOfSize:20];
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanBtn:)];
        [self.floatingBtn addGestureRecognizer:panBtn];
        [self addSubview:self.floatingBtn];

        // 2. BẢNG MENU CHÍNH
        self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 450)];
        self.menuPanel.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.menuPanel.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuPanel.layer.cornerRadius = 15;
        self.menuPanel.layer.borderWidth = 1;
        self.menuPanel.layer.borderColor = [UIColor cyanColor].CGColor;
        self.menuPanel.hidden = YES;
        [self addSubview:self.menuPanel];

        UIPanGestureRecognizer *panMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanMenu:)];
        [self.menuPanel addGestureRecognizer:panMenu];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 25)];
        title.text = @"UNIVERSAL OPTIMIZER";
        title.textColor = [UIColor cyanColor];
        title.font = [UIFont boldSystemFontOfSize:16];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:title];

        // --- Ô NHẬP SCALE (Hỗ trợ số thập phân) ---
        self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(20, 50, 130, 35)];
        self.scaleInput.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.scaleInput.textColor = [UIColor yellowColor];
        self.scaleInput.textAlignment = NSTextAlignmentCenter;
        self.scaleInput.keyboardType = UIKeyboardTypeDecimalPad;
        
        // Đọc float từ két sắt, nếu chưa có thì lấy Scale mặc định của màn hình
        float savedScale = [[NSUserDefaults standardUserDefaults] floatForKey:@"GO_Scale"];
        if (savedScale <= 0.1) savedScale = [UIScreen mainScreen].scale;
        self.scaleInput.text = [NSString stringWithFormat:@"%.2f", savedScale];
        self.scaleInput.layer.cornerRadius = 8;
        
        // Thêm thanh Done cho bàn phím
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44)];
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithTitle:@"Xong" style:UIBarButtonItemStyleDone target:self action:@selector(hideKeyboard)];
        [toolbar setItems:@[flexSpace, doneBtn]];
        self.scaleInput.inputAccessoryView = toolbar;
        [self.menuPanel addSubview:self.scaleInput];

        UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        applyBtn.frame = CGRectMake(160, 50, 80, 35);
        [applyBtn setTitle:@"Áp Dụng" forState:UIControlStateNormal];
        [applyBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [applyBtn addTarget:self action:@selector(applyScale) forControlEvents:UIControlEventTouchUpInside];
        [self.menuPanel addSubview:applyBtn];

        // 4 công tắc cũ
        [self createSwitchWithTitle:@"CPU Priority Boost" yPos:100 key:@"GO_CPUPriority"];
        [self createSwitchWithTitle:@"Input Lag Reduce" yPos:140 key:@"GO_InputLag"];
        [self createSwitchWithTitle:@"RAM Warn Bypass" yPos:180 key:@"GO_RAMBypass"];
        [self createSwitchWithTitle:@"Anti-Throttling" yPos:220 key:@"GO_ThermalBypass"];

        // 3 công tắc MỚI NHÉT THÊM VÀO ĐÂY
        [self createSwitchWithTitle:@"UI Anim Killer" yPos:260 key:@"GO_AnimKiller"];
        [self createSwitchWithTitle:@"Console Log Muter" yPos:300 key:@"GO_LogMuter"];
        [self createSwitchWithTitle:@"Block Analytics" yPos:340 key:@"GO_AnalyticsBlocker"];


        // --- CẢNH BÁO ---
        UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, 390, 260, 40)];
        warn.text = @"Bật/Tắt xong nhớ khởi động lại\ngame để có hiệu lực!";
        warn.numberOfLines = 2;
        warn.textColor = [UIColor orangeColor];
        warn.font = [UIFont systemFontOfSize:11];
        warn.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:warn];
    }
    return self;
}

// Hàm vẽ Switch rút gọn
- (void)createSwitchWithTitle:(NSString *)title yPos:(CGFloat)y key:(NSString *)key {
    UILabel *lbl = [[UILabel alloc] initWithFrame:CGRectMake(20, y, 160, 30)];
    lbl.text = title;
    lbl.textColor = [UIColor whiteColor];
    lbl.font = [UIFont systemFontOfSize:14];
    [self.menuPanel addSubview:lbl];

    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(180, y, 50, 30)];
    sw.on = [[NSUserDefaults standardUserDefaults] boolForKey:key];
    sw.accessibilityIdentifier = key; 
    [sw addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
    [self.menuPanel addSubview:sw];
}

// Các hàm xử lý sự kiện
- (void)toggleMenu { self.menuPanel.hidden = !self.menuPanel.hidden; [self hideKeyboard]; }
- (void)hideKeyboard { [self.scaleInput resignFirstResponder]; }

- (void)applyScale { 
    [self hideKeyboard];
    float val = [self.scaleInput.text floatValue];
    if (val <= 0.1) val = 0.1; // Chống người dùng nhập số âm hoặc 0
    self.scaleInput.text = [NSString stringWithFormat:@"%.2f", val];
    [[NSUserDefaults standardUserDefaults] setFloat:val forKey:@"GO_Scale"]; 
}

- (void)toggleSwitch:(UISwitch *)sender { 
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:sender.accessibilityIdentifier]; 
}

// Hàm hỗ trợ Kéo thả (Drag)
- (void)handlePanBtn:(UIPanGestureRecognizer *)reg {
    CGPoint loc = [reg translationInView:self];
    self.floatingBtn.center = CGPointMake(self.floatingBtn.center.x + loc.x, self.floatingBtn.center.y + loc.y);
    [reg setTranslation:CGPointZero inView:self];
}
- (void)handlePanMenu:(UIPanGestureRecognizer *)reg {
    CGPoint loc = [reg translationInView:self];
    self.menuPanel.center = CGPointMake(self.menuPanel.center.x + loc.x, self.menuPanel.center.y + loc.y);
    [reg setTranslation:CGPointZero inView:self];
}

// Hàm hỗ trợ ấn xuyên thấu (chỉ chặn click khi bấm đúng vào Menu/Nút)
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point)) return self.floatingBtn;
    if (!self.menuPanel.hidden && CGRectContainsPoint(self.menuPanel.frame, point)) return [self.menuPanel hitTest:[self convertPoint:point toView:self.menuPanel] withEvent:event];
    return nil;
}
@end

// Phải có cái biến static này để iOS nó không xóa mất UI của anh em mình!
static GOMenuWindow *goWindow;

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            goWindow = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            goWindow.windowScene = (UIWindowScene *)self;
            // Ép nó nổi lên
            goWindow.hidden = NO; 
        });
    });
}
%end
