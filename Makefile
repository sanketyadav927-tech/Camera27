# Camera27 Makefile
# Target: iPhone 8 Plus, iOS 16.7.16 (arm64, Rootless Dopamine / ElleKit)

THEOS_PACKAGE_SCHEME = rootless
TARGET := iphone:clang:latest:16.0
ARCHS = arm64

INSTALL_TARGET_PROCESSES = Camera

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Camera27

Camera27_FILES = Tweak.xm \
                 Sources/Camera27UI.m \
                 Sources/Camera27Controls.m \
                 Sources/Camera27Modes.m \
                 Sources/Camera27Zoom.m \
                 Sources/Camera27Settings.m \
                 Sources/Camera27Animations.m

Camera27_FRAMEWORKS = UIKit AVFoundation Photos CoreGraphics QuartzCore AudioToolbox
Camera27_CFLAGS = -fobjc-arc -IHeaders -Wno-unused-variable -Wno-unused-function

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Camera"
