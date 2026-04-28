#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

#include "imgui.h"
#include "imgui_impl_metal.h"

#define GO_SUITE @"com.universal.optimizer"
#define GO_PREFS [[NSUserDefaults alloc] initWithSuiteName:GO_SUITE]

// ═══════════════════════════════════════════════
//  Forward declare touch handler
// ═══════════════════════════════════════════════
void GO_ImGui_HandleTouch(UIEvent *event, CGSize screenSize);

// ═══════════════════════════════════════════════
//  State
// ═══════════════════════════════════════════════
static bool            gImGuiReady   = false;
static bool            gMenuOpen     = false;
static id<MTLDevice>   gDevice       = nil;
static id<MTLCommandQueue> gQueue    = nil;

// Switch states
static bool sw_cpu    = false;
static bool sw_input  = false;
static bool sw_ram    = false;
static bool sw_therm  = false;
static bool sw_anim   = false;
static bool sw_blur   = false;
static bool sw_net    = false;
static bool sw_hud    = false;
static float scaleVal = 1.0f;

static void loadPrefs() {
    NSUserDefaults *p = GO_PREFS;
    sw_cpu   = [p boolForKey:@"GO_CPUPriority"];
    sw_input = [p boolForKey:@"GO_InputLag"];
    sw_ram   = [p boolForKey:@"GO_RAMBypass"];
    sw_therm = [p boolForKey:@"GO_ThermalBypass"];
    sw_anim  = [p boolForKey:@"GO_AnimKiller"];
    sw_blur  = [p boolForKey:@"GO_AntiBlur"];
    sw_net   = [p boolForKey:@"GO_AnalyticsBlocker"];
    sw_hud   = [p boolForKey:@"GO_PerfHUD"];
    float sv = [p floatForKey:@"GO_Scale"];
    scaleVal = sv > 0.1f ? sv : 3.0f;
}

static void savePrefs() {
    NSUserDefaults *p = GO_PREFS;
    [p setBool:sw_cpu   forKey:@"GO_CPUPriority"];
    [p setBool:sw_input forKey:@"GO_InputLag"];
    [p setBool:sw_ram   forKey:@"GO_RAMBypass"];
    [p setBool:sw_therm forKey:@"GO_ThermalBypass"];
    [p setBool:sw_anim  forKey:@"GO_AnimKiller"];
    [p setBool:sw_blur  forKey:@"GO_AntiBlur"];
    [p setBool:sw_net   forKey:@"GO_AnalyticsBlocker"];
    [p setBool:sw_hud   forKey:@"GO_PerfHUD"];
    [p setFloat:scaleVal forKey:@"GO_Scale"];
}

// ═══════════════════════════════════════════════
//  ImGui Style
// ═══════════════════════════════════════════════
static void applyStyle() {
    ImGuiStyle &s = ImGui::GetStyle();
    s.WindowRounding    = 12.0f;
    s.FrameRounding     = 8.0f;
    s.ItemSpacing       = ImVec2(8, 6);
    s.WindowPadding     = ImVec2(12, 12);
    s.FramePadding      = ImVec2(8, 4);
    s.GrabRounding      = 6.0f;
    s.ScrollbarRounding = 6.0f;
    s.WindowBorderSize  = 1.0f;

    ImVec4 *c = s.Colors;
    c[ImGuiCol_WindowBg]       = ImVec4(0.05f, 0.06f, 0.12f, 0.96f);
    c[ImGuiCol_TitleBg]        = ImVec4(0.00f, 0.40f, 0.50f, 1.00f);
    c[ImGuiCol_TitleBgActive]  = ImVec4(0.00f, 0.55f, 0.70f, 1.00f);
    c[ImGuiCol_FrameBg]        = ImVec4(0.10f, 0.12f, 0.20f, 1.00f);
    c[ImGuiCol_FrameBgHovered] = ImVec4(0.15f, 0.20f, 0.30f, 1.00f);
    c[ImGuiCol_CheckMark]      = ImVec4(0.00f, 0.85f, 1.00f, 1.00f);
    c[ImGuiCol_SliderGrab]     = ImVec4(0.00f, 0.85f, 1.00f, 1.00f);
    c[ImGuiCol_Button]         = ImVec4(0.15f, 0.80f, 0.45f, 1.00f);
    c[ImGuiCol_ButtonHovered]  = ImVec4(0.20f, 0.90f, 0.55f, 1.00f);
    c[ImGuiCol_ButtonActive]   = ImVec4(0.10f, 0.65f, 0.35f, 1.00f);
    c[ImGuiCol_Header]         = ImVec4(0.00f, 0.50f, 0.65f, 0.60f);
    c[ImGuiCol_HeaderHovered]  = ImVec4(0.00f, 0.65f, 0.80f, 0.80f);
    c[ImGuiCol_Border]         = ImVec4(0.00f, 0.85f, 1.00f, 0.30f);
    c[ImGuiCol_Text]           = ImVec4(0.90f, 0.90f, 0.90f, 1.00f);
}

// ═══════════════════════════════════════════════
//  Menu UI
// ═══════════════════════════════════════════════
static void renderMenu(CGSize screen) {
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(screen.width, screen.height);

    ImGui::NewFrame();

    // Nút toggle nhỏ góc trái
    ImGui::SetNextWindowPos(ImVec2(16, 100), ImGuiCond_Always);
    ImGui::SetNextWindowSize(ImVec2(46, 46), ImGuiCond_Always);
    ImGui::PushStyleVar(ImGuiStyleVar_WindowPadding, ImVec2(0, 0));
    ImGui::PushStyleVar(ImGuiStyleVar_WindowMinSize, ImVec2(0, 0));
    ImGui::Begin("##btn", nullptr,
        ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize |
        ImGuiWindowFlags_NoScrollbar | ImGuiWindowFlags_NoMove |
        ImGuiWindowFlags_NoBackground);
    if (ImGui::Button("GO", ImVec2(46, 46)))
        gMenuOpen = !gMenuOpen;
    ImGui::End();
    ImGui::PopStyleVar(2);

    if (gMenuOpen) {
        bool isLandscape = screen.width > screen.height;

        if (isLandscape) {
            // LANDSCAPE: 2 cột
            ImGui::SetNextWindowSize(ImVec2(460, 200), ImGuiCond_Once);
        } else {
            // PORTRAIT: 1 cột
            ImGui::SetNextWindowSize(ImVec2(260, 340), ImGuiCond_Once);
        }
        ImGui::SetNextWindowPos(
            ImVec2(screen.width / 2, screen.height / 2),
            ImGuiCond_Once, ImVec2(0.5f, 0.5f));

        ImGui::Begin("✦  UNIVERSAL OPTIMIZER  ✦", &gMenuOpen,
            ImGuiWindowFlags_NoCollapse);

        // Scale row
        ImGui::Text("Scale");
        ImGui::SameLine();
        ImGui::SetNextItemWidth(120);
        ImGui::SliderFloat("##scale", &scaleVal, 0.1f, 3.0f, "%.2f");
        ImGui::SameLine();
        if (ImGui::Button("Apply")) savePrefs();

        ImGui::Separator();

        if (isLandscape) {
            // 2 cột landscape
            ImGui::Columns(2, nullptr, false);

            bool changed = false;
            changed |= ImGui::Checkbox("⚡ CPU Priority",   &sw_cpu);
            changed |= ImGui::Checkbox("🎯 Input Lag",      &sw_input);
            changed |= ImGui::Checkbox("💾 RAM Bypass",     &sw_ram);
            changed |= ImGui::Checkbox("🌡 Anti-Throttle",  &sw_therm);

            ImGui::NextColumn();

            changed |= ImGui::Checkbox("✂ Anim Killer",    &sw_anim);
            changed |= ImGui::Checkbox("🔍 Anti-Blur",      &sw_blur);
            changed |= ImGui::Checkbox("🛡 Block Analytics",&sw_net);
            changed |= ImGui::Checkbox("📊 Perf HUD",       &sw_hud);

            ImGui::Columns(1);
            if (changed) savePrefs();

        } else {
            // 1 cột portrait
            bool changed = false;
            changed |= ImGui::Checkbox("⚡ CPU Priority Boost",  &sw_cpu);
            changed |= ImGui::Checkbox("🎯 Input Lag Reduce",    &sw_input);
            changed |= ImGui::Checkbox("💾 RAM Warn Bypass",     &sw_ram);
            changed |= ImGui::Checkbox("🌡 Anti-Throttling",     &sw_therm);
            changed |= ImGui::Checkbox("✂ UI Anim Killer",      &sw_anim);
            changed |= ImGui::Checkbox("🔍 Anti-Blur GPU",       &sw_blur);
            changed |= ImGui::Checkbox("🛡 Block Analytics",     &sw_net);
            changed |= ImGui::Checkbox("📊 Performance HUD",     &sw_hud);
            if (changed) savePrefs();
        }

        ImGui::Separator();
        ImGui::TextColored(ImVec4(1.0f, 0.65f, 0.0f, 1.0f),
            "⚠ Restart game de co hieu luc");

        ImGui::End();
    }

    ImGui::Render();
}

// ═══════════════════════════════════════════════
//  Hook CAMetalLayer — init ImGui + render
// ═══════════════════════════════════════════════
%hook MTLCommandBuffer
- (void)presentDrawable:(id<CAMetalDrawable>)drawable {
    id<MTLDevice> dev = drawable.texture.device;
    if (!dev) { %orig; return; }

    if (!gImGuiReady) {
        gDevice = dev;
        gQueue = [dev newCommandQueue];
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGui::GetIO().IniFilename = nullptr;
        applyStyle();
        ImGui_ImplMetal_Init(dev);
        loadPrefs();
        gImGuiReady = true;
    }

    MTLRenderPassDescriptor *rpd = [MTLRenderPassDescriptor renderPassDescriptor];
    rpd.colorAttachments[0].texture = drawable.texture;
    rpd.colorAttachments[0].loadAction = MTLLoadActionLoad;
    rpd.colorAttachments[0].storeAction = MTLStoreActionStore;

    id<MTLCommandBuffer> imguiCmdBuf = [gQueue commandBuffer];
    CGSize screen = [UIScreen mainScreen].bounds.size;
    ImGui_ImplMetal_NewFrame(rpd);
    renderMenu(screen);

    id<MTLRenderCommandEncoder> enc = [imguiCmdBuf renderCommandEncoderWithDescriptor:rpd];
    ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), imguiCmdBuf, enc);
    [enc endEncoding];
    [imguiCmdBuf commit];

    %orig(drawable);
}
%end

// ═══════════════════════════════════════════════
//  Hook UIApplication sendEvent — touch input
// ═══════════════════════════════════════════════
%hook UIApplication

- (void)sendEvent:(UIEvent *)event {
    if (gImGuiReady && event.type == UIEventTypeTouches) {
        CGSize screen = [UIScreen mainScreen].bounds.size;
        GO_ImGui_HandleTouch(event, screen);
        // Chỉ chặn touch nếu ImGui đang capture
        if (ImGui::GetIO().WantCaptureMouse) return;
    }
    %orig;
}

%end

// ═══════════════════════════════════════════════
//  Inject — màng lọc app người dùng
// ═══════════════════════════════════════════════
%ctor {
    @autoreleasepool {
        NSString *bid  = [[NSBundle mainBundle] bundleIdentifier];
        NSString *path = [[NSBundle mainBundle] bundlePath];
        BOOL isApple   = [bid hasPrefix:@"com.apple."];
        BOOL isUserApp = [path containsString:@"/Application/"] ||
                         [path containsString:@"/Containers/"];
        if (isUserApp && !isApple) {
            %init;
        }
    }
}
