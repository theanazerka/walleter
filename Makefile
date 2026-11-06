# Walleter — скидочные карты в Passbook для iOS 6 (jailbreak, требует SigPass)
TARGET := iphone:clang:10.3:6.0
ARCHS := armv7
INSTALL_TARGET_PROCESSES = Walleter

# Старый dpkg в Cydia на iOS 6 понимает gzip
THEOS_PLATFORM_DEB_COMPRESSION_TYPE = gzip

# В .tbd из theos/sdks нет части 32-битных символов (они есть в iOS 6 в libobjc/libSystem),
# поэтому разрешаем искать их при запуске.
WL_ARMV7_LDFLAGS = -Wl,-U,_objc_msgSend_stret \
                   -Wl,-U,__Unwind_SjLj_Register -Wl,-U,__Unwind_SjLj_Unregister -Wl,-U,__Unwind_SjLj_Resume \
                   -Wl,-U,___divsi3 -Wl,-U,___udivsi3 -Wl,-U,___modsi3 -Wl,-U,___umodsi3 \
                   -Wl,-U,___divdi3 -Wl,-U,___udivdi3 -Wl,-U,___moddi3 -Wl,-U,___umoddi3

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME = Walleter

# ZBar (LGPL-2.1) — распознавание штрихкодов и QR, см. Vendor/zbar
ZBAR_DIR = Vendor/zbar
ZBAR_FILES = $(wildcard $(ZBAR_DIR)/zbar/*.c $(ZBAR_DIR)/zbar/decoder/*.c $(ZBAR_DIR)/zbar/qrcode/*.c)
$(foreach f,$(ZBAR_FILES),$(eval $(f)_CFLAGS = -w -include $(ZBAR_DIR)/zbar/config.h -I$(ZBAR_DIR)/zbar))

Walleter_FILES = $(wildcard Sources/*.m) $(ZBAR_FILES)
Walleter_CFLAGS = -fobjc-arc -ISources -I$(ZBAR_DIR)/include -Wno-deprecated-declarations
Walleter_FRAMEWORKS = UIKit Foundation CoreGraphics QuartzCore PassKit AVFoundation CoreMedia CoreVideo AudioToolbox
Walleter_LIBRARIES = z iconv
Walleter_LDFLAGS = $(WL_ARMV7_LDFLAGS)
Walleter_RESOURCE_DIRS = Resources

include $(THEOS_MAKE_PATH)/application.mk
