#import <UIKit/UIKit.h>
#include "imgui.h"

// ═══════════════════════════════════════════════
//  iOS Touch Bridge cho ImGui
//  Hook UIApplication sendEvent để feed touch vào ImGui IO
// ═══════════════════════════════════════════════

void GO_ImGui_HandleTouch(UIEvent *event, CGSize screenSize) {
    ImGuiIO &io = ImGui::GetIO();
    io.DisplaySize = ImVec2(screenSize.width, screenSize.height);

    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    if (!touch) return;

    CGPoint loc = [touch locationInView:nil];

    switch (touch.phase) {
        case UITouchPhaseBegan:
        case UITouchPhaseMoved:
            io.AddMousePosEvent(loc.x, loc.y);
            if (touch.phase == UITouchPhaseBegan)
                io.AddMouseButtonEvent(0, true);
            break;
        case UITouchPhaseEnded:
        case UITouchPhaseCancelled:
            io.AddMouseButtonEvent(0, false);
            break;
        default:
            break;
    }
}