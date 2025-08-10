export SHELL := /bin/bash


FRREEBSD_AMD64_VERSION := 14.3
FRREEBSD_AMD64_TARGET := amd64
FRREEBSD_AMD64_AARCH := amd64
FRREEBSD_AMD64_KERNCONFIG := GENERIC
FRREEBSD_AMD64_KERNDEBUG := --freebsd-with-default-options/debug-kernel
FRREEBSD_AMD64_VERBOSE :=
FRREEBSD_AMD64_ROOTFS := ufs
FRREEBSD_AMD64_HOSTNAME := rtbsd
FRREEBSD_AMD64_QEMU_EFI := 
FRREEBSD_AMD64_SRC_DIR := $(RTBSD_DIR)/upstream/freebsd
FRREEBSD_AMD64_ROOTFS_DIR := $(RTBSD_DIR)/build/freebsd-amd64-build$(RTBSD_DIR)/upstream/freebsd/amd64.amd64/sys/$(FRREEBSD_AMD64_KERNCONFIG)


freebsd_amd64_image:
	@echo "Building image for FreeBSD(AMD64)"
	$(RTBSD_DIR)/tools/cheribuild/cheribuild.py freebsd-amd64 disk-image-freebsd-amd64 \
		--source-root $(RTBSD_DIR)/upstream \
		--output-root $(RTBSD_DIR)/build/output \
		--build-root $(RTBSD_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(RTBSD_DIR)/build/extra-files \
		--disk-image-freebsd/hostname $(FRREEBSD_AMD64_HOSTNAME) \
		--disk-image-freebsd/rootfs-type $(FRREEBSD_AMD64_ROOTFS) \
		--skip-update \
		$(FRREEBSD_AMD64_VERBOSE)
	@cp $(RTBSD_DIR)/build/output/freebsd-amd64.img . -f
	@qemu-img resize freebsd-amd64.img 4G

freebsd_amd64_run:
	@echo "Run FreeBSD(AMD64)"
	qemu-system-x86_64 -m 2048 -smp 2 \
		-hda freebsd-amd64.img \
		-nographic