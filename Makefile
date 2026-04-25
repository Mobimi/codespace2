TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GameOptimizer

GameOptimizer_FILES = Tweak.x
GameOptimizer_CFLAGS = -fobjc-arc
GameOptimizer_FRAMEWORKS = UIKit QuartzCore Foundation CoreGraphics

include $(THEOS_MAKE_PATH)/tweak.mk
