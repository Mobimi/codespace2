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
        [self.floatingBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *panBtn = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanBtn:)];
        [self.floatingBtn addGestureRecognizer:panBtn];
        [self addSubview:self.floatingBtn];

        // 2. BẢNG MENU CHÍNH
        self.menuPanel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 260, 280)];
        self.menuPanel.center = CGPointMake(frame.size.width/2, frame.size.height/2);
        self.menuPanel.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.95];
        self.menuPanel.layer.cornerRadius = 15;
        self.menuPanel.layer.borderWidth = 1;
        self.menuPanel.layer.borderColor = [UIColor cyanColor].CGColor;
        self.menuPanel.hidden = YES;
        [self addSubview:self.menuPanel];

        // KÉO THẢ CHO MENU
        UIPanGestureRecognizer *panMenu = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanMenu:)];
        [self.menuPanel addGestureRecognizer:panMenu];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, 260, 25)];
        title.text = @"UNIVERSAL OPTIMIZER";
        title.textColor = [UIColor cyanColor];
        title.font = [UIFont boldSystemFontOfSize:16];
        title.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:title];

        // --- PHẦN SCALE ---
        self.scaleInput = [[UITextField alloc] initWithFrame:CGRectMake(20, 50, 130, 35)];
        self.scaleInput.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.scaleInput.textColor = [UIColor yellowColor];
        self.scaleInput.textAlignment = NSTextAlignmentCenter;
        self.scaleInput.keyboardType = UIKeyboardTypeDecimalPad;
        self.scaleInput.text = [NSString stringWithFormat:@"%.2f", [[NSUserDefaults standardUserDefaults] floatForKey:@"GO_Scale"] ?: [UIScreen mainScreen].scale];
        self.scaleInput.layer.cornerRadius = 8;
        [self.menuPanel addSubview:self.scaleInput];

        UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        applyBtn.frame = CGRectMake(160, 50, 80, 35);
        [applyBtn setTitle:@"Áp Dụng" forState:UIControlStateNormal];
        [applyBtn setTitleColor:[UIColor greenColor] forState:UIControlStateNormal];
        [applyBtn addTarget:self action:@selector(applyScale) forControlEvents:UIControlEventTouchUpInside];
        [self.menuPanel addSubview:applyBtn];

        // --- CÔNG TẮC CPU PRIORITY ---
        UILabel *cpuLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 100, 150, 30)];
        cpuLabel.text = @"CPU Priority Boost";
        cpuLabel.textColor = [UIColor whiteColor];
        cpuLabel.font = [UIFont systemFontOfSize:14];
        [self.menuPanel addSubview:cpuLabel];

        UISwitch *cpuSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 100, 50, 30)];
        cpuSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_CPUPriority"];
        [cpuSwitch addTarget:self action:@selector(toggleCPU:) forControlEvents:UIControlEventValueChanged];
        [self.menuPanel addSubview:cpuSwitch];

        // --- CÔNG TẮC INPUT LAG ---
        UILabel *lagLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 150, 150, 30)];
        lagLabel.text = @"Input Lag Reduce";
        lagLabel.textColor = [UIColor whiteColor];
        lagLabel.font = [UIFont systemFontOfSize:14];
        [self.menuPanel addSubview:lagLabel];

        UISwitch *lagSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(180, 150, 50, 30)];
        lagSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"GO_InputLag"];
        [lagSwitch addTarget:self action:@selector(toggleLag:) forControlEvents:UIControlEventValueChanged];
        [self.menuPanel addSubview:lagSwitch];

        UILabel *warn = [[UILabel alloc] initWithFrame:CGRectMake(0, 210, 260, 40)];
        warn.text = @"Bật/Tắt xong nhớ khởi động lại\ngame để có hiệu lực!";
        warn.numberOfLines = 2;
        warn.textColor = [UIColor orangeColor];
        warn.font = [UIFont systemFontOfSize:11];
        warn.textAlignment = NSTextAlignmentCenter;
        [self.menuPanel addSubview:warn];
    }
    return self;
}

- (void)toggleMenu { self.menuPanel.hidden = !self.menuPanel.hidden; [self.scaleInput resignFirstResponder]; }
- (void)applyScale { [[NSUserDefaults standardUserDefaults] setFloat:[self.scaleInput.text floatValue] forKey:@"GO_Scale"]; [self.scaleInput resignFirstResponder]; }
- (void)toggleCPU:(UISwitch *)sender { [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"GO_CPUPriority"]; }
- (void)toggleLag:(UISwitch *)sender { [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:@"GO_InputLag"]; }

// Kéo nút
- (void)handlePanBtn:(UIPanGestureRecognizer *)reg {
    CGPoint loc = [reg translationInView:self];
    self.floatingBtn.center = CGPointMake(self.floatingBtn.center.x + loc.x, self.floatingBtn.center.y + loc.y);
    [reg setTranslation:CGPointZero inView:self];
}
// Kéo Menu
- (void)handlePanMenu:(UIPanGestureRecognizer *)reg {
    CGPoint loc = [reg translationInView:self];
    self.menuPanel.center = CGPointMake(self.menuPanel.center.x + loc.x, self.menuPanel.center.y + loc.y);
    [reg setTranslation:CGPointZero inView:self];
}
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (!self.floatingBtn.hidden && CGRectContainsPoint(self.floatingBtn.frame, point)) return self.floatingBtn;
    if (!self.menuPanel.hidden && CGRectContainsPoint(self.menuPanel.frame, point)) return [self.menuPanel hitTest:[self convertPoint:point toView:self.menuPanel] withEvent:event];
    return nil;
}
@end

%hook UIWindowScene
- (void)_readySceneForConnection {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            GOMenuWindow *win = [[GOMenuWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            win.windowScene = (UIWindowScene *)self;
            win.hidden = NO;
        });
    });
}
%end
