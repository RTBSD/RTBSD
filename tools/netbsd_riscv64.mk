export SHELL := /bin/bash

NETBSD_RISCV64_MARCH := riscv
NETBSD_RISCV64_ARCH := riscv64
NETBSD_RISCV64_KERNCONFIG := GENERIC
NETBSD_RISCV64_MAXJOBS := 12
NETBSD_RISCV64_SRC_DIR := $(RTBSD_DIR)/upstream/netbsd
NETBSD_RISCV64_QEMU_EFI :=
NETBSD_RISCV64_IMAGES := $(RTBSD_DIR)/build/obj.$(NETBSD_RISCV64_MARCH)/releasedir/images

netbsd_riscv64_image:
	@echo "Building image for NetBSD(Riscv64)"
	@cd $(NETBSD_RISCV64_SRC_DIR) && \
		./build.sh -U -u -j$(NETBSD_RISCV64_MAXJOBS) \
		-m $(NETBSD_RISCV64_MARCH) \
		-a $(NETBSD_RISCV64_ARCH) \
		-O $(RTBSD_DIR)/build/obj.$(NETBSD_RISCV64_MARCH) \
		tools \
		releasekernel=$(NETBSD_RISCV64_KERNCONFIG) \
		release live-image
	@gunzip -d $(NETBSD_RISCV64_IMAGES)/NetBSD-10.1_STABLE-riscv64-live.img.gz
	@cp $(NETBSD_RISCV64_IMAGES)/NetBSD-10.1_STABLE-riscv64-live.img ./netbsd-riscv64.img
	@chmod +x ./netbsd-riscv64.img
	@qemu-img resize ./netbsd-riscv64.img 20g