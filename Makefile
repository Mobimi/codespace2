TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UniversalOptimizer

UniversalOptimizer_FILES = \
	native_menu.mm \
	scale.xm \
	cpu_priority_booster.xm \
	input_lag_reduce.xm \
	ram_optimizer.xm \
	thermal_bypass.xm \
	animation_killer.xm \
	network_blocker.xm \
	anti_blur.xm \
	render_optimize.xm

UniversalOptimizer_CFLAGS = \
	-fobjc-arc \
	-Wno-deprecated-declarations \
	-Wno-error

UniversalOptimizer_FRAMEWORKS = \
	UIKit \
	QuartzCore \
	Foundation \
	CoreGraphics \
	Metal \
	MetalKit \
	OpenGLES

include $(THEOS_MAKE_PATH)/tweak.mk
