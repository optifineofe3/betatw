ARCHS = arm64 arm64e
TARGET = iphone:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tweak

$(TWEAK_NAME)_FILES = $(shell find Sources \( -name '*.m' -o -name '*.xm' \))
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -ISources -ISources/UI -Wno-deprecated-declarations -Wno-unused-variable -Wno-unused-function -Wno-arc-performSelector-leaks
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation CoreGraphics Photos AVFoundation
$(TWEAK_NAME)_LOGOS_DEFAULT_GENERATOR = internal

after-stage::
	@echo ">>> Copying Tweak.bundle into .deb package..."
	@mkdir -p $(THEOS_STAGING_DIR)/Library/Application\ Support/Tweak
	@cp -a Tweak.bundle $(THEOS_STAGING_DIR)/Library/Application\ Support/Tweak

include $(THEOS_MAKE_PATH)/tweak.mk
