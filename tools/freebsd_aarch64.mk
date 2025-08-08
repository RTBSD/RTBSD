export SHELL := /bin/bash


FREEBSD_VERSION := 14.3
FREEBSD_TARGET := arm64
FREEBSD_AARCH := aarch64
FREEBSD_KERNCONFIG := GENERIC
FREEBSD_KERNDEBUG := --freebsd-with-default-options/debug-kernel
FREEBSD_VERBOSE :=
FREEBSD_ROOTFS := ufs
FREEBSD_HOSTNAME := rtbsd
FREEBSD_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
FREEBSD_SRC_DIR := $(RTBSD_DIR)/upstream/freebsd
FREEBSD_ROOTFS_DIR := $(RTBSD_DIR)/build/freebsd-aarch64-build$(RTBSD_DIR)/freebsd/arm64.aarch64/sys/$(FREEBSD_KERNCONFIG)

llvm_x86_64_debian_toolchain:
	@wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz
	@mkdir -p $(RTBSD_DIR)/tools/llvm-x86_64
	@tar -xvf clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
		-C $(RTBSD_DIR)/tools/llvm-x86_64 \
		 --strip-components=1
	@mkdir -p $(RTBSD_DIR)/build 
	@mkdir -p $(RTBSD_DIR)/build/output
	@ln -s $(RTBSD_DIR)/tools/llvm-x86_64 $(RTBSD_DIR)/build/output/upstream-llvm
	@echo "Setup x86_64 LLVM tools"

freebsd_aarch64_image:
	@echo "Building image for FreeBSD(AARCH64)"
	$(RTBSD_DIR)/tools/cheribuild/cheribuild.py freebsd-aarch64 disk-image-freebsd-aarch64 \
		--source-root $(RTBSD_DIR)/upstream \
		--output-root $(RTBSD_DIR)/build/output \
		--build-root $(RTBSD_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(RTBSD_DIR)/build/extra-files \
		--disk-image-freebsd/hostname $(FREEBSD_HOSTNAME) \
		--disk-image-freebsd/rootfs-type $(FREEBSD_ROOTFS) \
		--skip-update \
		$(FREEBSD_VERBOSE)
	@cp $(RTBSD_DIR)/build/output/freebsd-aarch64.img . -f

freebsd_aarch64_run:
	@echo "Run FreeBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(FREEBSD_QEMU_EFI) -nographic

freebsd_aarch64_clean:
	@echo "Clean FreeBSD(AARCH64)"
	@rm -rf $(RTBSD_DIR)/build/freebsd-aarch64-build
	@rm -rf $(RTBSD_DIR)/build/output
	@rm -rf $(RTBSD_DIR)/build/extra-files