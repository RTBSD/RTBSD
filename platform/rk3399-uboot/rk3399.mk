# RK3399 Build Configuration
RK3399_ATF_DIR := $(RTBSD_DIR)/platform/rk3399/arm-trusted-firmware
RK3399_ATF_REPO := https://github.com/ARM-software/arm-trusted-firmware.git
RK3399_ATF_COMMIT := 86ed8953b5233570c49a58060d424b7863d3a396
RK3399_ATF_PATCH := $(RTBSD_DIR)/platform/rk3399/atf-rk3399-baudrate.patch
RK3399_ATF_PLAT := rk3399
RK3399_ATF_TARGET := bl31

RK3399_UBOOT_DIR := $(RTBSD_DIR)/platform/rk3399/u-boot
RK3399_UBOOT_REPO := https://github.com/sigmaris/u-boot.git
RK3399_UBOOT_BRANCH := v2020.01-ci
RK3399_CONFIG := rockpro64-rk3399_defconfig
RK3399_CROSS_COMPILE := aarch64-linux-gnu-

RK3399_ARTIFACTS_DIR := $(RTBSD_DIR)/platform/rk3399/artifacts
RK3399_NPROC := $(shell nproc)

# Color definitions
RK3399_RED := \033[0;31m
RK3399_GREEN := \033[0;32m
RK3399_YELLOW := \033[1;33m
RK3399_NC := \033[0m

# Default target
.PHONY: rk3399_fw
rk3399_fw: rk3399_check_tools rk3399_build_atf rk3399_build_uboot_mmc

# Check required tools
.PHONY: rk3399_check_tools
rk3399_check_tools:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Checking required tools..."
	@for tool in git make $(RK3399_CROSS_COMPILE)gcc; do \
		if ! command -v $$tool >/dev/null 2>&1; then \
			echo -e "$(RK3399_RED)[ERROR]$(RK3399_NC) Missing tool: $$tool"; \
			exit 1; \
		fi; \
	done
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) All required tools are installed"

# ATF Build Targets
.PHONY: rk3399_build_atf
rk3399_build_atf: $(RK3399_ARTIFACTS_DIR)/bl31.elf

$(RK3399_ARTIFACTS_DIR)/bl31.elf:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Building ARM Trusted Firmware for RK3399..."
	@mkdir -p $(RK3399_ARTIFACTS_DIR)
	
	# Clone ATF repository if not exists
	@if [ ! -d "$(RK3399_ATF_DIR)" ]; then \
		echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Cloning ATF repository..."; \
		git clone $(RK3399_ATF_REPO) $(RK3399_ATF_DIR); \
	fi
	
	# Checkout specific commit and apply patch
	@cd $(RK3399_ATF_DIR) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Checking out commit $(RK3399_ATF_COMMIT)..." && \
	git checkout $(RK3399_ATF_COMMIT) && \
	if [ -f "../$(RK3399_ATF_PATCH)" ]; then \
		echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Applying patch $(RK3399_ATF_PATCH)..."; \
		git am "../$(RK3399_ATF_PATCH)"; \
	fi
	
	# Build ATF
	@cd $(RK3399_ATF_DIR) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Building ATF..." && \
	make realclean && \
	CFLAGS="-Wno-attributes" make -j$(RK3399_NPROC) CROSS_COMPILE=$(RK3399_CROSS_COMPILE) PLAT=$(RK3399_ATF_PLAT) $(RK3399_ATF_TARGET)
	
	# Copy bl31.elf to artifacts directory
	@cp $(RK3399_ATF_DIR)/build/$(RK3399_ATF_PLAT)/release/$(RK3399_ATF_TARGET)/$(RK3399_ATF_TARGET).elf $(RK3399_ARTIFACTS_DIR)/
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) ATF build completed: $(RK3399_ARTIFACTS_DIR)/bl31.elf"

# U-Boot Build Targets
.PHONY: rk3399_build_uboot_mmc
rk3399_build_uboot_mmc: rk3399_build_atf
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Building MMC version of U-Boot..."
	$(MAKE) rk3399_build_uboot_internal \
		RK3399_DEFCONFIG=rockpro64-rk3399_defconfig \
		RK3399_IMG1TYPE=rksd \
		RK3399_IMG1NAME=mmc_idbloader.img \
		RK3399_IMG2NAME=mmc_u-boot.itb  \
		RK3399_ENVNAME=mmc_default_env.img \
		RK3399_ARTIFACT=mmc_u-boot

# Internal U-Boot build function
.PHONY: rk3399_build_uboot_internal
rk3399_build_uboot_internal:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Building U-Boot: $(RK3399_DEFCONFIG)"
	@mkdir -p $(RK3399_ARTIFACTS_DIR)/$(RK3399_ARTIFACT)
	
	# Check if U-Boot directory exists, clone if not
	@if [ ! -d "$(RK3399_UBOOT_DIR)" ]; then \
		echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Cloning U-Boot repository..."; \
		git clone -b $(RK3399_UBOOT_BRANCH) $(RK3399_UBOOT_REPO) $(RK3399_UBOOT_DIR); \
	fi
	
	# Set BL31 environment variable and build U-Boot
	@export BL31="$(realpath $(RK3399_ARTIFACTS_DIR)/bl31.elf)"; \
	cd $(RK3399_UBOOT_DIR) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Configuring U-Boot..." && \
	make mrproper && \
	make $(RK3399_DEFCONFIG) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Building U-Boot..." && \
	make -j$(RK3399_NPROC) CROSS_COMPILE=$(RK3399_CROSS_COMPILE) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Creating idbloader.img..." && \
	./tools/mkimage -n rk3399 -T $(RK3399_IMG1TYPE) -d tpl/u-boot-tpl.bin:spl/u-boot-spl.bin $(RK3399_IMG1NAME) && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Creating environment image..." && \
	cp env/built-in.o built_in_env.o && \
	$(RK3399_CROSS_COMPILE)objcopy -O binary -j ".rodata.default_environment" built_in_env.o && \
	tr '\0' '\n' < built_in_env.o | sed '/^$$/d' > built_in_env.txt && \
	./tools/mkenvimage -s 0x8000 -o $(RK3399_ENVNAME) built_in_env.txt && \
	echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Copying artifacts..." && \
	cp u-boot.itb $(RK3399_ARTIFACTS_DIR)/$(RK3399_ARTIFACT)/$(RK3399_IMG2NAME) && \
	cp $(RK3399_IMG1NAME) $(RK3399_ENVNAME) $(RK3399_ARTIFACTS_DIR)/$(RK3399_ARTIFACT)/

# Create combined MMC image (20MB fixed size)
.PHONY: rk3399_create_mmc_image
rk3399_create_mmc_image: rk3399_build_uboot_mmc
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Creating combined MMC image..."
	@mkdir -p $(RK3399_ARTIFACTS_DIR)/mmc_images
	
	# Check required files exist
	@if [ ! -f "$(RK3399_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img" ]; then \
		echo -e "$(RK3399_RED)[ERROR]$(RK3399_NC) mmc_idbloader.img not found"; \
		exit 1; \
	fi
	@if [ ! -f "$(RK3399_ARTIFACTS_DIR)/mmc_u-boot/mmc_u-boot.itb" ]; then \
		echo -e "$(RK3399_RED)[ERROR]$(RK3399_NC) mmc_u-boot.itb not found"; \
		exit 1; \
	fi
	
	# Create 20MB empty image
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Creating empty 20MB image..."
	@dd if=/dev/zero of=$(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img bs=1M count=20 status=none
	
	# Write mmc_idbloader.img at offset 64 sectors (32KB)
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Writing mmc_idbloader.img at offset 64 sectors (32KB)..."
	@dd if=$(RK3399_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img of=$(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img conv=notrunc bs=512 seek=64 status=none
	
	# Write mmc_u-boot.itb at offset 16384 sectors (8MB)
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Writing mmc_u-boot.itb at offset 16384 sectors (8MB)..."
	@dd if=$(RK3399_ARTIFACTS_DIR)/mmc_u-boot/mmc_u-boot.itb of=$(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img conv=notrunc bs=512 seek=16384 status=none
	
	# Create compressed version
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Creating compressed version..."
	@gzip -c $(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img > $(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img.gz
	
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) MMC combined image created:"
	@echo "  - $(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img (20MB raw image)"
	@echo "  - $(RK3399_ARTIFACTS_DIR)/mmc_images/mmc_combined.img.gz (compressed)"

# Clean targets
.PHONY: rk3399_clean
rk3399_clean:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Cleaning build files..."
	@rm -rf $(RK3399_ARTIFACTS_DIR)
	@if [ -d "$(RK3399_ATF_DIR)" ]; then \
		cd $(RK3399_ATF_DIR) && make realclean; \
	fi
	@if [ -d "$(RK3399_UBOOT_DIR)" ]; then \
		cd $(RK3399_UBOOT_DIR) && make mrproper; \
	fi
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Clean completed"

.PHONY: rk3399_distclean
rk3399_distclean:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Removing source directories..."
	@rm -rf $(RK3399_ARTIFACTS_DIR) $(RK3399_ATF_DIR) $(RK3399_UBOOT_DIR)
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Directories removed"

# Status and info targets
.PHONY: rk3399_status
rk3399_status:
	@echo -e "$(RK3399_GREEN)[INFO]$(RK3399_NC) Build status check:"
	@if [ -d "$(RK3399_ATF_DIR)" ]; then \
		echo "✓ ATF source directory exists"; \
		if [ -f "$(RK3399_ARTIFACTS_DIR)/bl31.elf" ]; then \
			echo "✓ ATF built"; \
		else \
			echo "✗ ATF not built"; \
		fi; \
	else \
		echo "✗ ATF source directory does not exist"; \
	fi
	@if [ -d "$(RK3399_UBOOT_DIR)" ]; then \
		echo "✓ U-Boot source directory exists"; \
		if [ -f "$(RK3399_ARTIFACTS_DIR)/spi_u-boot/spi_idbloader.img" ]; then \
			echo "✓ SPI U-Boot built"; \
		else \
			echo "✗ SPI U-Boot not built"; \
		fi; \
		if [ -f "$(RK3399_ARTIFACTS_DIR)/mmc_u-boot/mmc_idbloader.img" ]; then \
			echo "✓ MMC U-Boot built"; \
		else \
			echo "✗ MMC U-Boot not built"; \
		fi; \
	else \
		echo "✗ U-Boot source directory does not exist"; \
	fi

.PHONY: rk3399_info
rk3399_info:
	@echo "RK3399 Build Configuration:"
	@echo "  ATF Directory: $(RK3399_ATF_DIR)"
	@echo "  ATF Repository: $(RK3399_ATF_REPO)"
	@echo "  ATF Commit: $(RK3399_ATF_COMMIT)"
	@echo "  ATF Patch: $(RK3399_ATF_PATCH)"
	@echo "  U-Boot Directory: $(RK3399_UBOOT_DIR)"
	@echo "  U-Boot Repository: $(RK3399_UBOOT_REPO)"
	@echo "  U-Boot Branch: $(RK3399_UBOOT_BRANCH)"
	@echo "  Cross Compiler: $(RK3399_CROSS_COMPILE)"
	@echo "  Artifacts Directory: $(RK3399_ARTIFACTS_DIR)"
	@echo "  Parallel Jobs: $(RK3399_NPROC)"

.PHONY: rk3399_help
rk3399_help:
	@echo "RK3399 Build Script"
	@echo ""
	@echo "Available targets:"
	@echo "  rk3399_fw                - Complete build process (ATF + U-Boot + SPI images)"
	@echo "  rk3399_build_atf          - Build ARM Trusted Firmware only"
	@echo "  rk3399_build_uboot_mmc    - Build MMC version of U-Boot"
	@echo "  rk3399_create_mmc_image   - Create combined MMC image (20MB)"
	@echo "  rk3399_clean              - Clean build files"
	@echo "  rk3399_distclean          - Full clean (remove all directories)"
	@echo "  rk3399_status             - Show build status"
	@echo "  rk3399_info               - Show configuration info"
	@echo "  rk3399_help               - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make rk3399_fw           # Complete build"
	@echo "  make rk3399_build_atf     # Build ATF only"
	@echo "  make rk3399_clean         # Clean build files"

# Update the all target to include mmc image creation
.PHONY: rk3399_fw
rk3399_fw: rk3399_check_tools rk3399_build_atf rk3399_build_uboot_mmc rk3399_create_mmc_image