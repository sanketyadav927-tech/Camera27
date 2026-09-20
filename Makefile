# Camera27 Makefile
# Target: iPhone 8 Plus, iOS 16.7.16 (arm64, Rootless Dopamine / ElleKit)

THEOS_PACKAGE_SCHEME = rootless
TARGET              := iphone:clang:latest:16.0
ARCHS               = arm64

INSTALL_TARGET_PROCESSES = Camera

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Camera27

Camera27_FILES = Tweak.xm \
                 Sources/Camera27Settings.m \
                 Sources/Camera27Animations.m \
                 Sources/Camera27Controls.m \
                 Sources/Camera27Zoom.m \
                 Sources/Camera27Modes.m \
                 Sources/Camera27UI.m

Camera27_FRAMEWORKS = UIKit AVFoundation Photos CoreGraphics QuartzCore AudioToolbox

# Warning suppression flags — required for iOS private framework headers:
# -Wno-incompatible-property-type : private header property attrs vs UIKit base class
# -Wno-incompatible-pointer-types : forward-declared private classes used as typed ptrs
# -Wno-deprecated-declarations    : some private selectors carry deprecated attrs
# -Wno-objc-protocol-method-implementation
# -Wno-unguarded-availability-new : iOS 16 selectors without @available wrappers
# -Wno-nullability-completeness   : private headers may omit nullability annotations
Camera27_CFLAGS = -fobjc-arc -IHeaders \
                  -Wno-unused-variable \
                  -Wno-unused-function \
                  -Wno-incompatible-property-type \
                  -Wno-incompatible-pointer-types \
                  -Wno-deprecated-declarations \
                  -Wno-objc-protocol-method-implementation \
                  -Wno-unguarded-availability-new \
                  -Wno-nullability-completeness

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Camera"
