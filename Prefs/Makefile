BUNDLE_NAME = RotateWallPrefs
RotateWallPrefs_FILES = $(wildcard *.m)
RotateWallPrefs_PRIVATE_FRAMEWORKS = Preferences
RotateWallPrefs_EXTRA_FRAMEWORKS += Cephei CepheiPrefs
RotateWallPrefs_FRAMEWORKS = PhotosUI
RotateWallPrefs_CFLAGS = -fobjc-arc
RotateWallPrefs_INSTALL_PATH = /Library/PreferenceBundles
ADDITIONAL_CFLAGS += -DTHEOS_LEAN_AND_MEAN

ifneq ($(THEOS_PACKAGE_SCHEME),rootless)
ADDITIONAL_CFLAGS += -D XINA_SUPPORT
endif

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/bundle.mk
