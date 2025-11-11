# SystemReady IR RK3399 Firmware Build Makefile
# Target: Toybrick RK3399 Pro (可修改为其他平台)

# 配置变量
TOYBRICK_TARGET ?= TB-RK3399proD
TOYBRICK_MANIFEST ?= TB-RK3399proD.xml
TOYBRICK_BRANCH ?= refs/tags/tb-rk3399prod-21.09
TOYBRICK_REPO_URL ?= https://gitlab.arm.com/systemready/firmware-build/rk3399-manifest
TOYBRICK_BUILD_DIR ?= $(RTBSD_DIR)/platform/toybrick/build
TOYBRICK_JOBS ?= $(shell nproc)

# 输出镜像文件
TOYBRICK_OUTPUT_IMAGE ?= $(TOYBRICK_BUILD_DIR)/toybrick-systemready-sdcard.img
TOYBRICK_IMAGE_SIZE ?= 4G

# 工具检查
TOYBRICK_REPO_TOOL ?= $(shell which repo)
TOYBRICK_RKDEVTOOL ?= $(shell which rkdeveloptool)
TOYBRICK_PARTED ?= $(shell which parted)
TOYBRICK_MKFS ?= $(shell which mkfs.vfat)
TOYBRICK_MCOPY ?= $(shell which mcopy)
TOYBRICK_DD ?= $(shell which dd)

.PHONY: toybrick_all toybrick_init toybrick_sync toybrick_toolchain toybrick_build toybrick_capsule toybrick_image toybrick_flash toybrick_clean toybrick_distclean toybrick_help toybrick_status

toybrick_all: toybrick_image

toybrick_init:
	@echo "Initializing repo for $(TOYBRICK_TARGET)..."
	@if [ -z "$(TOYBRICK_REPO_TOOL)" ]; then \
		echo "Error: repo tool not found. Please install repo first."; \
		exit 1; \
	fi
	@mkdir -p $(TOYBRICK_BUILD_DIR)
	@cd $(TOYBRICK_BUILD_DIR) && \
	if [ ! -d .repo ]; then \
		$(TOYBRICK_REPO_TOOL) init -u $(TOYBRICK_REPO_URL) -m $(TOYBRICK_MANIFEST) -b $(TOYBRICK_BRANCH); \
	else \
		echo "Repo already initialized"; \
	fi

toybrick_sync: toybrick_init
	@echo "Syncing source code with $(TOYBRICK_JOBS) jobs..."
	@cd $(TOYBRICK_BUILD_DIR) && $(TOYBRICK_REPO_TOOL) sync -j$(TOYBRICK_JOBS) --no-clone-bundle

toybrick_toolchain: toybrick_sync
	@echo "Building toolchains..."
#	@cd $(TOYBRICK_BUILD_DIR)/build && make -j2 toolchains

toybrick_build: toybrick_toolchain
	@echo "Building firmware for $(TOYBRICK_TARGET)..."
	@cd $(TOYBRICK_BUILD_DIR)/build && CFLAGS="-Wno-attributes" make -j$(TOYBRICK_JOBS)

toybrick_capsule: toybrick_build
	@echo "Building capsule update..."
	@cd $(TOYBRICK_BUILD_DIR)/build && make -j$(TOYBRICK_JOBS) capsule

toybrick_image: toybrick_build
	@echo "Creating bootable SD card image for Toybrick..."
	@# 检查必要工具
	@if [ -z "$(TOYBRICK_PARTED)" ]; then \
		echo "Error: parted not found. Please install parted."; \
		exit 1; \
	fi
	@if [ -z "$(TOYBRICK_MKFS)" ]; then \
		echo "Error: mkfs.vfat not found. Please install dosfstools."; \
		exit 1; \
	fi
	@# 创建空镜像文件
	$(TOYBRICK_DD) if=/dev/zero of=$(TOYBRICK_OUTPUT_IMAGE) bs=1 count=0 seek=$(TOYBRICK_IMAGE_SIZE) 2>/dev/null
	@# 创建分区表
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) mklabel gpt
	@# 创建引导分区 (64MB FAT32)
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) mkpart boot fat32 1MiB 65MiB
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) set 1 boot on
	@# 创建EFI系统分区 (128MB)
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) mkpart efi fat32 65MiB 193MiB
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) set 2 esp on
	@# 创建根文件系统分区
	$(TOYBRICK_PARTED) -s $(TOYBRICK_OUTPUT_IMAGE) mkpart rootfs ext4 193MiB 100%
	@# 设置loop设备
	@sudo bash -c "\
	LOOP_DEV=\$$(losetup --find --show --partscan $(TOYBRICK_OUTPUT_IMAGE)); \
	BOOT_PART=\$${LOOP_DEV}p1; \
	EFI_PART=\$${LOOP_DEV}p2; \
	ROOTFS_PART=\$${LOOP_DEV}p3; \
	\
	# 格式化引导分区 \
	$(TOYBRICK_MKFS) -F 32 -n TOYBRICK_BOOT \$${BOOT_PART}; \
	\
	# 复制引导文件到引导分区 \
	mkdir -p /mnt/toybrick_boot; \
	mount \$${BOOT_PART} /mnt/toybrick_boot; \
	cp $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/idbloader.img /mnt/toybrick_boot/; \
	cp $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/uboot.itb /mnt/toybrick_boot/; \
	cp $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/capsule/*.cap /mnt/toybrick_boot/ 2>/dev/null || true; \
	\
	# 创建U-Boot启动脚本 \
	echo 'bootcmd=mmc dev 0; fatload mmc 0:1 \$${kernel_addr_r} Image; fatload mmc 0:1 \$${fdt_addr_r} \$${fdtfile}; booti \$${kernel_addr_r} - \$${fdt_addr_r}' > /mnt/toybrick_boot/boot.scr; \
	\
	umount /mnt/toybrick_boot; \
	rm -rf /mnt/toybrick_boot; \
	\
	# 格式化EFI系统分区 \
	$(TOYBRICK_MKFS) -F 32 -n TOYBRICK_EFI \$${EFI_PART}; \
	\
	# 格式化根文件系统分区 \
	mkfs.ext4 -L TOYBRICK_ROOTFS \$${ROOTFS_PART}; \
	\
	losetup -d \$${LOOP_DEV}; \
	"
	@echo "Toybrick SD card image created: $(TOYBRICK_OUTPUT_IMAGE)"
	@echo "Image size: $(TOYBRICK_IMAGE_SIZE)"
	@echo "Partitions: boot(FAT32), efi(FAT32), rootfs(ext4)"

toybrick_flash: toybrick_build
	@echo "Flashing Toybrick device in bootrom mode..."
	@if [ -z "$(TOYBRICK_RKDEVTOOL)" ]; then \
		echo "Error: rkdeveloptool not found. Please install it first."; \
		exit 1; \
	fi
	@echo "Please ensure the Toybrick device is in bootrom mode and connected"
	@echo "Flashing loader images..."
	@sudo $(TOYBRICK_RKDEVTOOL) db $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/miniloader.bin
	@sudo $(TOYBRICK_RKDEVTOOL) pt -p $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/parameter.txt
	@sudo $(TOYBRICK_RKDEVTOOL) ul $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/idbloader.img
	@sudo $(TOYBRICK_RKDEVTOOL) ul $(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/uboot.itb
	@echo "Toybrick flashing completed"

toybrick_status:
	@echo "Toybrick Build Status:"
	@if [ -d "$(TOYBRICK_BUILD_DIR)/.repo" ]; then \
		echo "✓ Repo initialized"; \
	else \
		echo "✗ Repo not initialized"; \
	fi
	@if [ -f "$(TOYBRICK_BUILD_DIR)/build/$(TOYBRICK_TARGET)/uboot.itb" ]; then \
		echo "✓ Firmware built"; \
	else \
		echo "✗ Firmware not built"; \
	fi
	@if [ -f "$(TOYBRICK_OUTPUT_IMAGE)" ]; then \
		echo "✓ SD card image created"; \
		ls -lh "$(TOYBRICK_OUTPUT_IMAGE)"; \
	else \
		echo "✗ SD card image not created"; \
	fi

toybrick_clean:
	@echo "Cleaning Toybrick build files..."
	@if [ -d "$(TOYBRICK_BUILD_DIR)/build" ]; then \
		cd $(TOYBRICK_BUILD_DIR)/build && make clean; \
	fi
	@rm -f $(TOYBRICK_OUTPUT_IMAGE)
	@echo "Toybrick build files cleaned"

toybrick_distclean:
	@echo "Removing all Toybrick build files and source..."
	@rm -rf $(TOYBRICK_BUILD_DIR)
	@rm -f toybrick-*.img
	@echo "Toybrick build directory removed"

toybrick_help:
	@echo "Toybrick SystemReady IR RK3399 Firmware Build System"
	@echo ""
	@echo "Targets:"
	@echo "  toybrick_all          - Complete build process (default)"
	@echo "  toybrick_init         - Initialize repo repository"
	@echo "  toybrick_sync         - Sync source code"
	@echo "  toybrick_toolchain    - Build toolchains"
	@echo "  toybrick_build        - Build firmware"
	@echo "  toybrick_capsule      - Build capsule update"
	@echo "  toybrick_image        - Create bootable SD card image"
	@echo "  toybrick_flash        - Flash to device (requires bootrom mode)"
	@echo "  toybrick_status       - Show build status"
	@echo "  toybrick_clean        - Clean build files"
	@echo "  toybrick_distclean    - Remove all files"
	@echo "  toybrick_help         - Show this help"
	@echo ""
	@echo "Configuration variables:"
	@echo "  TOYBRICK_TARGET      = $(TOYBRICK_TARGET)"
	@echo "  TOYBRICK_MANIFEST    = $(TOYBRICK_MANIFEST)"
	@echo "  TOYBRICK_BRANCH      = $(TOYBRICK_BRANCH)"
	@echo "  TOYBRICK_BUILD_DIR   = $(TOYBRICK_BUILD_DIR)"
	@echo "  TOYBRICK_OUTPUT_IMAGE = $(TOYBRICK_OUTPUT_IMAGE)"
	@echo "  TOYBRICK_IMAGE_SIZE  = $(TOYBRICK_IMAGE_SIZE)"
	@echo ""
	@echo "Usage examples:"
	@echo "  make toybrick_all                    # Complete build"
	@echo "  make toybrick_image                  # Create SD card image only"
	@echo "  make toybrick_flash                  # Flash to device"
	@echo "  make toybrick_status                 # Check build status"
	@echo "  make toybrick_distclean              # Clean everything"

# 默认目标
.DEFAULT_GOAL := toybrick_all