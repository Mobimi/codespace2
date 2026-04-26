TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = UniversalOptimizer

# Danh sách 4 file chiến lược
UniversalOptimizer_FILES = GUI.x scale.xm input_lag_reduce.xm cpu_priority_booster.xm

UniversalOptimizer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
UniversalOptimizer_FRAMEWORKS = UIKit QuartzCore Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
