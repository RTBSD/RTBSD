export SHELL := /bin/bash

RTEMS_VERSION := 6
RTEMS_SRC_DIR := $(RTBSD_DIR)/rtos/rtems-space/rtems
RTEMS_LIBBSD_DIR := $(RTBSD_DIR)/rtos/rtems-space/rtems-libbsd
RTEMS_APP_DIR := $(RTBSD_DIR)/rtos/rtems-space/app
RTEMS_RSB_DIR := $(RTBSD_DIR)/build/rtems-source-builder
RTEMS_DTS_DIR := $(RTBSD_DIR)/rtos/rtems-space/configs/dts
RTEMS_DTB_DIR := $(RTBSD_DIR)/rtos/rtems-space/configs/dtb
RTEMS_BSP_INI_DIR := $(RTBSD_DIR)/rtos/rtems-space/configs/bsp
RTEMS_LIBBSD_BUILDSET := $(RTBSD_DIR)/rtos/rtems-space/configs/buildset
RTEMS_TOOL_PATH := $(RTBSD_DIR)/build/rtems
RTEMS_AARCH64_TOOL_PREFIX := $(RTEMS_TOOL_PATH)/toolchain/aarch64-$(RTEMS_VERSION)
#RTEMS_AMD64_TOOL_PREFIX := $(RTEMS_TOOL_PATH)/toolchain/x86_64-$(RTEMS_VERSION)

# void build_rtems_toolchain
#    $(1) == toolchain install dir
#    $(2) == rtems source builder dir
#    $(3) == rtems version
#    $(4) == rtems aarch
define build_rtems_toolchain
	@##H## Build the toolchain, just run in the first time.
	@mkdir $(1) -p
	@rm -rf $(2)/rtems/build
	@cd $(2) && ./source-builder/sb-check
	# build gcc toolchain
	@cd $(2)/rtems && ../source-builder/sb-set-builder \
		--log=$(1)/rtems-$(3)-toolchain-$(4).log \
		--prefix=$(1) \
		--without-rtems \
		$(3)/rtems-$(4)
	# build device-tree compiler
	@cd $(2)/rtems && ../source-builder/sb-set-builder \
		--log=$(1)/rtems-$(3)-dtc-$(4).log \
		--prefix=$(1) \
		devel/dtc
endef

# void get_rtems_bsp_default_config
#    $(1) == rtems source dir
#    $(2) == rtems bsp arch
#    $(3) == rtems bsp board
define get_rtems_bsp_default_config
	@##H## Get the BSP default configs.
	cd $(1) && ./waf bspdefaults --rtems-bsps=$(2)/$(3) > config.ini
endef

# void build_rtems_devtree
#   $(1) == target bsp name
define build_rtems_devtree
	@##H## Build the device tree.
	mkdir -p $(RTEMS_DTB_DIR)
	dtc -@ -I dts -O dtb -o $(RTEMS_DTB_DIR)/$(1).dtb $(RTEMS_DTS_DIR)/$(1).dts
	rtems-bin2c -N firefly_dtb $(RTEMS_DTB_DIR)/$(1).dtb  $(RTEMS_DTB_DIR)/$(1).c
endef

# void config_rtems_bsp
#    $(1) == rtems bsp config
#    $(2) == rtems source dir
define config_rtems_bsp
	@##H## Build the BSP.
	cd $(2) && cat $(RTEMS_BSP_INI_DIR)/$(1) >> ./config.ini && echo -e "\n" >> ./config.ini  
endef

# void build_rtems_bsp
#    $(1) == bsp install dir
#    $(2) == rtems source dir
define build_rtems_bsp
	cd $(2) && ./waf configure \
		--prefix=$(1)
	cd $(2) && ./waf
	cd $(2) && ./waf install
endef

# void build_rtems_libbsd
#    $(1) == libbsd install dir
#    $(2) == libbsd source dir
#    $(3) == rtems version
#    $(4) == rtems bsp arch
#    $(5) == rtems bsp board
#    $(6) == rtems libbsd config
#    $(7) == rtems libbsd netconfig
define build_rtems_libbsd
	@##H## Build the libbsd.
	cd $(2) && ./waf configure \
		--prefix=$(1) \
		--rtems-tools=$(1) \
		--rtems-bsps=$(4)/$(5) \
		--enable-warnings \
		--optimization=g \
		--rtems-version=$(3) \
		--buildset=$(RTEMS_LIBBSD_BUILDSET)/$(6)
	cd $(2) && ./waf
	cd $(2) && ./waf install
endef

# void build_rtems_appimage
#   $(1) == target bsp name
define build_rtems_appimage
	@##H## Build the application.
	source ./rtos/rtems-space/env/env_$(1).sh && \
		cd $(RTEMS_APP_DIR) && make clean image
endef

rtems_tools:
	@##H## Build the toolchain, just run in the first time.
	@if [ ! -f "rtems-source-builder-6.1.tar.xz" ]; then \
		wget https://ftp.rtems.org/pub/rtems/releases/6/6.1/sources/rtems-source-builder-6.1.tar.xz; \
		mkdir -p $(RTEMS_RSB_DIR); \
		tar -xvf rtems-source-builder-6.1.tar.xz \
			-C $(RTEMS_RSB_DIR) \
			--strip-components=1; \
	fi
	$(call build_rtems_toolchain,$(RTEMS_AARCH64_TOOL_PREFIX),$(RTEMS_RSB_DIR),$(RTEMS_VERSION),aarch64)
#	$(call build_rtems_toolchain,$(RTEMS_AMD64_TOOL_PREFIX),$(RTEMS_RSB_DIR),$(RTEMS_VERSION),x86_64)

rtems_bsp_list:
	@cd $(RTEMS_SRC_DIR) && ./waf bsplist

rtems_clean:
	@rm $(RTEMS_SRC_DIR)/build -rf
	@rm $(RTEMS_SRC_DIR)/.lock-waf* -f

rtems_firefly_v2_image:
	@echo -n > $(RTEMS_SRC_DIR)/config.ini
	$(call config_rtems_bsp,firefly_v2.ini,$(RTEMS_SRC_DIR))
	$(call build_rtems_bsp,$(RTEMS_AARCH64_TOOL_PREFIX),$(RTEMS_SRC_DIR))
	$(call build_rtems_appimage,firefly_v2)

rtems_zynq_image:
	@echo -n > $(RTEMS_SRC_DIR)/config.ini
	$(call get_rtems_bsp_default_config,$(RTEMS_SRC_DIR),aarch64,a53_lp64_qemu)
	$(call build_rtems_bsp,$(RTEMS_AARCH64_TOOL_PREFIX),$(RTEMS_SRC_DIR))
	@cp $(RTEMS_SRC_DIR)/build/aarch64/a53_lp64_qemu/testsuites/samples/hello.exe ./rtems.exe

rtems_zynq_run:
	@qemu-system-aarch64 -no-reboot -nographic -serial mon:stdio \
		-machine virt,gic-version=3 -cpu cortex-a53 -m 4096 -kernel rtems.exe