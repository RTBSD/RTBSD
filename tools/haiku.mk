
HAIKU_SRC_DIR  := $(RTBSD_DIR)/downstream/haiku/haiku
HAIKU_BUILDTOOLS_DIR  := $(RTBSD_DIR)/downstream/haiku/buildtools
HAIKU_ARM64_BUILD_DIR := $(RTBSD_DIR)/build/haiku.arm64
HAIKU_ARM64_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
HAIKU_X64_BUILD_DIR := $(RTBSD_DIR)/build/haiku.x64

haiku_arm64_image:
	@mkdir -p $(HAIKU_ARM64_BUILD_DIR)
	@cd $(HAIKU_ARM64_BUILD_DIR) && \
	export HAIKU_REVISION=hrevarm64 && \
	$(HAIKU_SRC_DIR)/configure -j12 \
		--cross-tools-source \
		$(HAIKU_BUILDTOOLS_DIR) \
		--build-cross-tools arm64 && \
	jam -j12 -q @minimum-mmc
#	jam -j12 -q @minimum-raw esp.image \
		haiku-minimum.image
	

haiku_arm64_run:
#	@qemu-system-aarch64 -bios $(HAIKU_ARM64_QEMU_EFI) \
		-M virt -cpu max -m 2048 \
		-device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 \
		-device virtio-blk-device,drive=x1,bus=virtio-mmio-bus.1 \
		-drive file=$(HAIKU_ARM64_BUILD_DIR)/objects/haiku/arm64/release/efi/system/boot/esp.image,if=none,format=raw,id=x0 \
		-drive file=$(HAIKU_ARM64_BUILD_DIR)/haiku-minimum.image,if=none,format=raw,id=x1 \
		-device virtio-keyboard-device,bus=virtio-mmio-bus.2 \
		-device virtio-tablet-device,bus=virtio-mmio-bus.3 \
		-device ramfb -serial stdio
	@qemu-system-aarch64 -bios u-boot.bin -M virt -cpu max -m 2048 \
		-device virtio-blk-device,drive=x0,bus=virtio-mmio-bus.0 \
		-drive file=$(HAIKU_ARM64_BUILD_DIR)/haiku-mmc.image,if=none,format=raw,id=x0 \
		-device virtio-keyboard-device,bus=virtio-mmio-bus.1 \
		-device virtio-tablet-device,bus=virtio-mmio-bus.2 \
		-device ramfb -serial stdio

haiku_x64_image:
	@mkdir -p $(HAIKU_X64_BUILD_DIR)
	@cd $(HAIKU_X64_BUILD_DIR) && \
	export HAIKU_REVISION=hrevx64 &&\
	$(HAIKU_SRC_DIR)/configure -j12 \
		--cross-tools-source \
		$(HAIKU_BUILDTOOLS_DIR) \
		--build-cross-tools x86_64 && \
	jam -q -j12 @nightly-raw