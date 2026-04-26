TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GameOptimizer

# THÊM TÊN 2 FILE MỚI VÀO ĐÂY (Cách nhau bằng dấu cách)
GameOptimizer_FILES = Tweak.x InputLagReducer.x CPUPriorityBooster.x

GameOptimizer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
GameOptimizer_FRAMEWORKS = UIKit QuartzCore Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
