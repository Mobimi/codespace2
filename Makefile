TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UniversalOptimizer

IMGUI_DIR = imgui

UniversalOptimizer_FILES = \
	imgui_hook.xm \
	imgui_touch.mm \
	scale.xm \
	cpu_priority_booster.xm \
	input_lag_reduce.xm \
	ram_optimizer.xm \
	thermal_bypass.xm \
	animation_killer.xm \
	network_blocker.xm \
	anti_blur.xm \
	$(IMGUI_DIR)/imgui.cpp \
	$(IMGUI_DIR)/imgui_draw.cpp \
	$(IMGUI_DIR)/imgui_tables.cpp \
	$(IMGUI_DIR)/imgui_widgets.cpp \
	$(IMGUI_DIR)/backends/imgui_impl_metal.mm

UniversalOptimizer_CFLAGS = \
	-fobjc-arc \
	-Wno-deprecated-declarations \
	-Wno-error \
	-I$(IMGUI_DIR) \
	-I$(IMGUI_DIR)/backends

UniversalOptimizer_CCFLAGS = \
	-std=c++17 \
	-fno-exceptions \
	-I$(IMGUI_DIR) \
	-I$(IMGUI_DIR)/backends

UniversalOptimizer_FRAMEWORKS = \
	UIKit \
	QuartzCore \
	Foundation \
	CoreGraphics \
	Metal \
	MetalKit

include $(THEOS_MAKE_PATH)/tweak.mk