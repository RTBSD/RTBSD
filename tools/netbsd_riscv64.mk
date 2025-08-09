export SHELL := /bin/bash

NETBSD_RISCV64_MARCH := riscv
NETBSD_RISCV64_ARCH := riscv64
NETBSD_RISCV64_KERNCONFIG := GENERIC
NETBSD_RISCV64_MAXJOBS := 12
NETBSD_RISCV64_SRC_DIR := $(RTBSD_DIR)/upstream/netbsd
NETBSD_RISCV64_QEMU_EFI :=

netbsd_riscv64_image:
	@echo "Building image for NetBSD(Riscv64)"
	@cd $(NETBSD_RISCV64_SRC_DIR) && \
		./build.sh -U -u -j$(NETBSD_RISCV64_MAXJOBS) \
		-m $(NETBSD_RISCV64_MARCH) \
		-a $(NETBSD_RISCV64_ARCH) \
		-O $(RTBSD_DIR)/build/obj.$(NETBSD_RISCV64_MARCH) \
		tools release live-image install-image \
		disk-image=riscv64 \
		releasekernel=$(NETBSD_RISCV64_KERNCONFIG)