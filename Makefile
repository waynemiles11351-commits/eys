TARGET := iphone:clang:18.0:18.0
ARCHS := arm64
DEBUG = 0
FINALPACKAGE = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = GGDIdentityOverlay

GGDIdentityOverlay_FILES = Tweak.xm GGDCore.mm GGDOverlay.mm
GGDIdentityOverlay_CFLAGS = -fobjc-arc -std=c++17
GGDIdentityOverlay_FRAMEWORKS = UIKit Foundation QuartzCore
GGDIdentityOverlay_PRIVATE_FRAMEWORKS = Metal

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 Goose 2>/dev/null || true"
