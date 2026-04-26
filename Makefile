TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UniversalOptimizer

# Khai báo đủ 1 Trạm điều khiển và 5 Công nhân
UniversalOptimizer_FILES = GUI.x scale.xm cpu_priority_booster.xm input_lag_reduce.xm ram_optimizer.xm thermal_bypass.xm animation_killer.xm network_blocker.xm anti_blur.xm

UniversalOptimizer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
UniversalOptimizer_FRAMEWORKS = UIKit QuartzCore Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
