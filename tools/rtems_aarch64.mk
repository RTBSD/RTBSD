export SHELL := /bin/bash

RTEMS_VERSION := 6
RTEMS_SRC_DIR := $(RTBSD_DIR)/rtos/rtems
RTEMS_RSB_DIR := $(RTBSD_DIR)/build/rtems-source-builder
RTEMS_AARCH64_TOOL_PATH := $(RTBSD_DIR)/build/rtems
RTEMS_AARCH64_TOOL_PREFIX := $(RTEMS_AARCH64_TOOL_PATH)/toolchain/aarch64-$(RTEMS_VERSION)

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

rtems_aarch64_image:
	@echo -n > $(RTEMS_SRC_DIR)/config.ini
	$(call config_rtems_bsp,qemu-a53-bsp.ini,$(RTEMS_SRC_DIR))
	$(call build_rtems_bsp,$(RTEMS_AARCH64_TOOL_PREFIX),$(RTEMS_SRC_DIR))

rtems_aarch64_run:
	@qemu-system-aarch64 -no-reboot -nographic -serial mon:stdio \
		-machine virt,gic-version=3 -cpu cortex-a53 -m 4096 -kernel rtems.exe