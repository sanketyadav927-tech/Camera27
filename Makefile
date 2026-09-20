THEOS_PACKAGE_SCHEME = rootless
TARGET = iphone:clang:latest:16.0
ARCHS = arm64
INSTALL_TARGET_PROCESSES = Camera

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Camera27
Camera27_FILES = Tweak.xm Sources/Camera27Settings.m Sources/Camera27Runtime.m Sources/Camera27UI.m
Camera27_FRAMEWORKS = UIKit AVFoundation Photos AudioToolbox
Camera27_CFLAGS = -fobjc-arc -IHeaders -Werror -Wno-unguarded-availability-new

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Camera"
