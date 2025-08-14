export SHELL := /bin/bash

RTEMS_VERSION := 6
RTEMS_SRC_DIR := $(RTBSD_DIR)/rtos/rtemsspace/rtems
RTEMS_RSB_DIR := $(RTBSD_DIR)/build/rtems-source-builder
RTEMS_TOOL_PATH := $(RTBSD_DIR)/build/rtems
RTEMS_AARCH64_TOOL_PREFIX := $(RTEMS_TOOL_PATH)/toolchain/aarch64-$(RTEMS_VERSION)
RTEMS_AMD64_TOOL_PREFIX := $(RTEMS_TOOL_PATH)/toolchain/x86_64-$(RTEMS_VERSION)


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
	cd $(1) && sed -i \
		-e "s|RTEMS_POSIX_API = False|RTEMS_POSIX_API = True|" \
		-e "s|BUILD_SAMPLES = False|BUILD_SAMPLES = True|" \
		-e "s|RTEMS_SMP = False|RTEMS_SMP = True|" \
		-e "s|BUILD_SMPTESTS = False|BUILD_SMPTESTS = True|" \
		-e "s|BUILD_TESTS = False|BUILD_TESTS = True|" \
		-e "s|BUILD_ADATESTS = False|BUILD_ADATESTS = True|" \
		-e "s|BUILD_BENCHMARKS = False|BUILD_BENCHMARKS = True|" \
		-e "s|BUILD_FSTESTS = False|BUILD_FSTESTS = True|" \
		-e "s|BUILD_LIBTESTS = False|BUILD_LIBTESTS = True|" \
		-e "s|BUILD_MPTESTS = False|BUILD_MPTESTS = False|" \
		-e "s|BUILD_PSXTESTS = False|BUILD_PSXTESTS = True|" \
		-e "s|BUILD_PSXTMTESTS = False|BUILD_PSXTMTESTS = True|" \
		-e "s|BUILD_RHEALSTONE = False|BUILD_RHEALSTONE = True|" \
		-e "s|BUILD_SMPTESTS = False|BUILD_SMPTESTS = False|" \
		-e "s|BUILD_TMTESTS = False|BUILD_TMTESTS = True|" \
		-e "s|BUILD_UNITTESTS = False|BUILD_UNITTESTS = True|" \
		-e "s|BUILD_VALIDATIONTESTS = False|BUILD_VALIDATIONTESTS = True|" \
		-e "s|AARCH64_FLUSH_CACHE_BOOT_UP = False|AARCH64_FLUSH_CACHE_BOOT_UP = True|" \
		config.ini
	cd $(1) && cat config.ini
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
	$(call build_rtems_toolchain,$(RTEMS_AMD64_TOOL_PREFIX),$(RTEMS_RSB_DIR),$(RTEMS_VERSION),x86_64)

rtems_bsp_list:
	@cd $(RTEMS_SRC_DIR) && ./waf bsplist

rtems_aarch64_image:
	@echo -n > $(RTEMS_SRC_DIR)/config.ini
	$(call get_rtems_bsp_default_config,$(RTEMS_SRC_DIR),aarch64,a53_lp64_qemu)
	$(call build_rtems_bsp,$(RTEMS_AARCH64_TOOL_PREFIX),$(RTEMS_SRC_DIR))
	@cp $(RTEMS_SRC_DIR)/build/aarch64/a53_lp64_qemu/testsuites/samples/hello.exe ./rtems.exe

rtems_aarch64_run:
	@qemu-system-aarch64 -no-reboot -nographic -serial mon:stdio \
		-machine virt,gic-version=3 -cpu cortex-a53 -m 4096 -kernel rtems.exe