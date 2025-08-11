export SHELL := /bin/bash


FRREEBSD_RISCV64_VERSION := 14.3
FRREEBSD_RISCV64_TARGET := riscv
FRREEBSD_RISCV64_AARCH := riscv64
FRREEBSD_RISCV64_KERNCONFIG := GENERIC
FRREEBSD_RISCV64_KERNDEBUG := --freebsd-with-default-options/debug-kernel
FRREEBSD_RISCV64_VERBOSE :=
FRREEBSD_RISCV64_ROOTFS := ufs
FRREEBSD_RISCV64_HOSTNAME := rtbsd
FRREEBSD_RISCV64_QEMU_EFI := 
FRREEBSD_RISCV64_SRC_DIR := $(RTBSD_DIR)/upstream/freebsd
FRREEBSD_RISCV64_ROOTFS_DIR := $(RTBSD_DIR)/build/freebsd-riscv64-build$(RTBSD_DIR)/upstream/freebsd/riscv64.riscv64/sys/$(FRREEBSD_RISCV64_KERNCONFIG)


freebsd_riscv64_image:
	@echo "Building image for FreeBSD(RiscV64)"
	$(RTBSD_DIR)/tools/cheribuild/cheribuild.py freebsd-riscv64 disk-image-freebsd-riscv64 \
		--source-root $(RTBSD_DIR)/upstream \
		--output-root $(RTBSD_DIR)/build/output \
		--build-root $(RTBSD_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(RTBSD_DIR)/build/extra-files \
		--disk-image-freebsd/hostname $(FRREEBSD_RISCV64_HOSTNAME) \
		--disk-image-freebsd/rootfs-type $(FRREEBSD_RISCV64_ROOTFS) \
		--skip-update \
		$(FRREEBSD_RISCV64_VERBOSE)
	@cp $(RTBSD_DIR)/build/output/freebsd-riscv64.img . -f
	@qemu-img resize freebsd-riscv64.img 4G