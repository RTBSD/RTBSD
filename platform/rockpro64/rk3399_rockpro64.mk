# ROCKPRO64 Build Configuration
ROCKPRO64_ATF_DIR := $(RTBSD_DIR)/platform/rockpro64/arm-trusted-firmware
ROCKPRO64_ATF_REPO := https://github.com/ARM-software/arm-trusted-firmware.git
ROCKPRO64_ATF_COMMIT := 86ed8953b5233570c49a58060d424b7863d3a396
ROCKPRO64_ATF_PATCH := $(RTBSD_DIR)/platform/rockpro64/atf-rk3399-baudrate.patch
ROCKPRO64_ATF_PLAT := rk3399
ROCKPRO64_ATF_TARGET := bl31

ROCKPRO64_UBOOT_DIR := $(RTBSD_DIR)/platform/rockpro64/u-boot
ROCKPRO64_UBOOT_REPO := https://github.com/sigmaris/u-boot.git
ROCKPRO64_UBOOT_BRANCH := v2020.01-ci
ROCKPRO64_CONFIG := rockpro64-rk3399_defconfig
ROCKPRO64_CROSS_COMPILE := aarch64-linux-gnu-

ROCKPRO64_ARTIFACTS_DIR := $(RTBSD_DIR)/platform/rockpro64/artifacts
ROCKPRO64_NPROC := $(shell nproc)

# Color definitions
ROCKPRO64_RED := \033[0;31m
ROCKPRO64_GREEN := \033[0;32m
ROCKPRO64_YELLOW := \033[1;33m
ROCKPRO64_NC := \033[0m

# Default target
.PHONY: rockpro64_all
rockpro64_all: rockpro64_check_tools rockpro64_build_atf rockpro64_build_uboot_mmc rockpro64_create_mmc_image

# Check required tools
.PHONY: rockpro64_check_tools
rockpro64_check_tools:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Checking required tools..."
	@for tool in git make $(ROCKPRO64_CROSS_COMPILE)gcc; do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo -e "$(ROCKPRO64_RED)[ERROR]$(ROCKPRO64_NC) Missing tool: $$tool"; \
			exit 1; \
		fi; \
	done
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) All required tools are installed"

# ATF Build Targets
.PHONY: rockpro64_build_atf
rockpro64_build_atf: $(ROCKPRO64_ARTIFACTS_DIR)/bl31.elf

$(ROCKPRO64_ARTIFACTS_DIR)/bl31.elf:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Building ARM Trusted Firmware for ROCKPRO64..."
	@mkdir -p $(ROCKPRO64_ARTIFACTS_DIR)
	
	# Clone ATF repository if not exists
	@if [ ! -d "$(ROCKPRO64_ATF_DIR)" ]; then \
		echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Cloning ATF repository..."; \
		git clone $(ROCKPRO64_ATF_REPO) $(ROCKPRO64_ATF_DIR); \
	fi
	
	# Checkout specific commit and apply patch
	@cd $(ROCKPRO64_ATF_DIR) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Checking out commit $(ROCKPRO64_ATF_COMMIT)..." && \
	git checkout $(ROCKPRO64_ATF_COMMIT) && \
	if [ -f "../$(ROCKPRO64_ATF_PATCH)" ]; then \
		echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Applying patch $(ROCKPRO64_ATF_PATCH)..."; \
		git am "../$(ROCKPRO64_ATF_PATCH)"; \
	fi
	
	# Build ATF
	@cd $(ROCKPRO64_ATF_DIR) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Building ATF..." && \
	make realclean && \
	CFLAGS="-Wno-attributes" make -j$(ROCKPRO64_NPROC) CROSS_COMPILE=$(ROCKPRO64_CROSS_COMPILE) PLAT=$(ROCKPRO64_ATF_PLAT) $(ROCKPRO64_ATF_TARGET)
	
	# Copy bl31.elf to artifacts directory
	@cp $(ROCKPRO64_ATF_DIR)/build/$(ROCKPRO64_ATF_PLAT)/release/$(ROCKPRO64_ATF_TARGET)/$(ROCKPRO64_ATF_TARGET).elf $(ROCKPRO64_ARTIFACTS_DIR)/
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) ATF build completed: $(ROCKPRO64_ARTIFACTS_DIR)/bl31.elf"

# U-Boot Build Targets
.PHONY: rockpro64_build_uboot_mmc
rockpro64_build_uboot_mmc: rockpro64_build_atf
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Building MMC version of U-Boot..."
	$(MAKE) rockpro64_build_uboot_internal \
		ROCKPRO64_DEFCONFIG=rockpro64-rk3399_defconfig \
		ROCKPRO64_IMG1TYPE=rksd \
		ROCKPRO64_IMG1NAME=mmc_idbloader.img \
		ROCKPRO64_IMG2NAME=mmc_u-boot.itb  \
		ROCKPRO64_ENVNAME=mmc_default_env.img \
		ROCKPRO64_ARTIFACT=mmc_u-boot

# Internal U-Boot build function
.PHONY: rockpro64_build_uboot_internal
rockpro64_build_uboot_internal:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Building U-Boot: $(ROCKPRO64_DEFCONFIG)"
	@mkdir -p $(ROCKPRO64_ARTIFACTS_DIR)/$(ROCKPRO64_ARTIFACT)
	
	# Check if U-Boot directory exists, clone if not
	@if [ ! -d "$(ROCKPRO64_UBOOT_DIR)" ]; then \
		echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Cloning U-Boot repository..."; \
		git clone -b $(ROCKPRO64_UBOOT_BRANCH) $(ROCKPRO64_UBOOT_REPO) $(ROCKPRO64_UBOOT_DIR); \
	fi
	
	# Set BL31 environment variable and build U-Boot
	@export BL31="$(realpath $(ROCKPRO64_ARTIFACTS_DIR)/bl31.elf)"; \
	cd $(ROCKPRO64_UBOOT_DIR) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Configuring U-Boot..." && \
	make mrproper && \
	make $(ROCKPRO64_DEFCONFIG) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Building U-Boot..." && \
	make -j$(ROCKPRO64_NPROC) CROSS_COMPILE=$(ROCKPRO64_CROSS_COMPILE) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Creating idbloader.img..." && \
	./tools/mkimage -n rk3399 -T $(ROCKPRO64_IMG1TYPE) -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin $(ROCKPRO64_IMG1NAME) && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Creating environment image..." && \
	cp env/built-in.o built_in_env.o && \
	$(ROCKPRO64_CROSS_COMPILE)objcopy -O binary -j ".rodata.default_environment" built_in_env.o && \
	tr '\0' '\n' < built_in_env.o | sed '/^$$/d' > built_in_env.txt && \
	./tools/mkenvimage -s 0x8000 -o $(ROCKPRO64_ENVNAME) built_in_env.txt && \
	echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Copying artifacts..." && \
	cp u-boot.itb $(ROCKPRO64_ARTIFACTS_DIR)/$(ROCKPRO64_ARTIFACT)/$(ROCKPRO64_IMG2NAME) && \
	cp $(ROCKPRO64_IMG1NAME) $(ROCKPRO64_ENVNAME) $(ROCKPRO64_ARTIFACTS_DIR)/$(ROCKPRO64_ARTIFACT)/

# Create combined MMC image (20MB fixed size)
.PHONY: rockpro64_create_mmc_image
rockpro64_create_mmc_image: rockpro64_build_uboot_mmc
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Creating combined MMC image..."
	@mkdir -p $(ROCKPRO64_ARTIFACTS_DIR)/mmc_images
	
	# Check required files exist
	@if [ ! -f "$(ROCKPRO64_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img" ]; then \
		echo -e "$(ROCKPRO64_RED)[ERROR]$(ROCKPRO64_NC) mmc_idbloader.img not found"; \
		exit 1; \
	fi
	@if [ ! -f "$(ROCKPRO64_ARTIFACTS_DIR)/mmc_u-boot/mmc_u-boot.itb" ]; then \
		echo -e "$(ROCKPRO64_RED)[ERROR]$(ROCKPRO64_NC) mmc_u-boot.itb not found"; \
		exit 1; \
	fi
	
	# Create 20MB empty image
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Creating empty 20MB image..."
	@dd if=/dev/zero of=$(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img bs=1M count=20 status=none
	
	# Write mmc_idbloader.img at offset 64 sectors (32KB)
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Writing mmc_idbloader.img at offset 64 sectors (32KB)..."
	@dd if=$(ROCKPRO64_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img of=$(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img conv=notrunc bs=512 seek=64 status=none
	
	# Write mmc_u-boot.itb at offset 16384 sectors (8MB)
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Writing mmc_u-boot.itb at offset 16384 sectors (8MB)..."
	@dd if=$(ROCKPRO64_ARTIFACTS_DIR)/mmc_u-boot/mmc_u-boot.itb of=$(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img conv=notrunc bs=512 seek=16384 status=none
	
	# Create compressed version
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Creating compressed version..."
	@gzip -c $(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img > $(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img.gz
	
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) MMC combined image created:"
	@echo "  - $(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img (20MB raw image)"
	@echo "  - $(ROCKPRO64_ARTIFACTS_DIR)/mmc_images/mmc_combined.img.gz (compressed)"

# Clean targets
.PHONY: rockpro64_clean
rockpro64_clean:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Cleaning build files..."
	@rm -rf $(ROCKPRO64_ARTIFACTS_DIR)
	@if [ -d "$(ROCKPRO64_ATF_DIR)" ]; then \
		cd $(ROCKPRO64_ATF_DIR) && make realclean; \
	fi
	@if [ -d "$(ROCKPRO64_UBOOT_DIR)" ]; then \
		cd $(ROCKPRO64_UBOOT_DIR) && make mrproper; \
	fi
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Clean completed"

.PHONY: rockpro64_distclean
rockpro64_distclean:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Removing source directories..."
	@rm -rf $(ROCKPRO64_ARTIFACTS_DIR) $(ROCKPRO64_ATF_DIR) $(ROCKPRO64_UBOOT_DIR)
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Directories removed"

# Status and info targets
.PHONY: rockpro64_status
rockpro64_status:
	@echo -e "$(ROCKPRO64_GREEN)[INFO]$(ROCKPRO64_NC) Build status check:"
	@if [ -d "$(ROCKPRO64_ATF_DIR)" ]; then \
		echo "✓ ATF source directory exists"; \
		if [ -f "$(ROCKPRO64_ARTIFACTS_DIR)/bl31.elf" ]; then \
			echo "✓ ATF built"; \
		else \
			echo "✗ ATF not built"; \
		fi; \
	else \
		echo "✗ ATF source directory does not exist"; \
	fi
	@if [ -d "$(ROCKPRO64_UBOOT_DIR)" ]; then \
		echo "✓ U-Boot source directory exists"; \
		if [ -f "$(ROCKPRO64_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img" ]; then \
			echo "✓ MMC U-Boot built"; \
		else \
			echo "✗ MMC U-Boot not built"; \
		fi; \
	else \
		echo "✗ U-Boot source directory does not exist"; \
	fi

.PHONY: rockpro64_info
rockpro64_info:
	@echo "ROCKPRO64 Build Configuration:"
	@echo "  ATF Directory: $(ROCKPRO64_ATF_DIR)"
	@echo "  ATF Repository: $(ROCKPRO64_ATF_REPO)"
	@echo "  ATF Commit: $(ROCKPRO64_ATF_COMMIT)"
	@echo "  ATF Patch: $(ROCKPRO64_ATF_PATCH)"
	@echo "  U-Boot Directory: $(ROCKPRO64_UBOOT_DIR)"
	@echo "  U-Boot Repository: $(ROCKPRO64_UBOOT_REPO)"
	@echo "  U-Boot Branch: $(ROCKPRO64_UBOOT_BRANCH)"
	@echo "  Cross Compiler: $(ROCKPRO64_CROSS_COMPILE)"
	@echo "  Artifacts Directory: $(ROCKPRO64_ARTIFACTS_DIR)"
	@echo "  Parallel Jobs: $(ROCKPRO64_NPROC)"

.PHONY: rockpro64_help
rockpro64_help:
	@echo "ROCKPRO64 Build Script"
	@echo ""
	@echo "Available targets:"
	@echo "  rockpro64_all                - Complete build process (ATF + U-Boot + MMC image)"
	@echo "  rockpro64_build_atf          - Build ARM Trusted Firmware only"
	@echo "  rockpro64_build_uboot_mmc    - Build MMC version of U-Boot"
	@echo "  rockpro64_create_mmc_image   - Create combined MMC image (20MB)"
	@echo "  rockpro64_clean              - Clean build files"
	@echo "  rockpro64_distclean          - Full clean (remove all directories)"
	@echo "  rockpro64_status             - Show build status"
	@echo "  rockpro64_info               - Show configuration info"
	@echo "  rockpro64_help               - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make rockpro64_all           # Complete build"
	@echo "  make rockpro64_build_atf     # Build ATF only"
	@echo "  make rockpro64_create_mmc_image # Create MMC image only"
	@echo "  make rockpro64_clean         # Clean build files"