# Walleter — скидочные карты в Passbook для iOS 6 (jailbreak, требует SigPass)
TARGET := iphone:clang:10.3:6.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = Walleter

# Старый dpkg в Cydia на iOS 6 понимает gzip
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Walleter

Walleter_FILES = $(wildcard Sources/*.m)
Walleter_CFLAGS = -fobjc-arc -ISources -Wno-deprecated-declarations
Walleter_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore PassKit
Walleter_LIBRARIES = z
Walleter_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
