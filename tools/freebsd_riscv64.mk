export SHELL := /bin/bash


FREEBSD_VERSION := 14.3
FREEBSD_TARGET := riscv
FREEBSD_AARCH := riscv64
FREEBSD_KERNCONFIG := GENERIC
FREEBSD_KERNDEBUG := --freebsd-with-default-options/debug-kernel
FREEBSD_VERBOSE :=
FREEBSD_ROOTFS := ufs
FREEBSD_HOSTNAME := rtbsd
FREEBSD_QEMU_EFI := 
FREEBSD_SRC_DIR := $(RTBSD_DIR)/upstream/freebsd
FREEBSD_ROOTFS_DIR := $(RTBSD_DIR)/build/freebsd-riscv64-build$(RTBSD_DIR)/upstream/freebsd/riscv64.riscv64/sys/$(FREEBSD_KERNCONFIG)


freebsd_riscv64_image:
	@echo "Building image for FreeBSD(RiscV64)"
	$(RTBSD_DIR)/tools/cheribuild/cheribuild.py freebsd-riscv64 disk-image-freebsd-riscv64 \
		--source-root $(RTBSD_DIR)/upstream \
		--output-root $(RTBSD_DIR)/build/output \
		--build-root $(RTBSD_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(RTBSD_DIR)/build/extra-files \
		--disk-image-freebsd/hostname $(FREEBSD_HOSTNAME) \
		--disk-image-freebsd/rootfs-type $(FREEBSD_ROOTFS) \
		--skip-update \
		$(FREEBSD_VERBOSE)
	@cp $(RTBSD_DIR)/build/output/freebsd-riscv64.img . -f
	@qemu-img resize freebsd-riscv64.img 4G
