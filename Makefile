# Walleter — скидочные карты в Passbook для iOS 6 (jailbreak, требует SigPass)
TARGET := iphone:clang:10.3:6.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = Walleter

# Старый dpkg в Cydia на iOS 6 понимает gzip
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

WL_ARMV7_LDFLAGS = -Wl,-U,_objc_msgSend_stret -Wl,-U,__Unwind_SjLj_Register \
                   -Wl,-U,__Unwind_SjLj_Unregister -Wl,-U,__Unwind_SjLj_Resume

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Walleter

Walleter_FILES = $(wildcard Sources/*.m)
Walleter_CFLAGS = -fobjc-arc -ISources -Wno-deprecated-declarations
Walleter_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore PassKit
Walleter_LIBRARIES = z
# В .tbd из theos/sdks нет 32-битных символов; в iOS 6 они есть в libobjc/libSystem
Walleter_LDFLAGS = $(WL_ARMV7_LDFLAGS)
Walleter_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
