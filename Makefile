TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GameOptimizer

GameOptimizer_FILES = Tweak.x
# Dòng CFLAGS đã được thêm bùa chống lỗi đồ cổ
GameOptimizer_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -Wno-error
GameOptimizer_FRAMEWORKS = UIKit QuartzCore Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
