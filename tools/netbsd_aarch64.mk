export SHELL := /bin/bash

NETBSD_MARCH := evbarm
NETBSD_ARCH := aarch64
NETBSD_KERNCONFIG := GENERIC64
NETBSD_MAXJOBS := 12
NETBSD_SRC_DIR := $(RTBSD_DIR)/upstream/netbsd
NETBSD_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
NETBSD_IMAGES := $(RTBSD_DIR)/build/obj.$(NETBSD_ARCH)/releasedir/$(NETBSD_MARCH)-$(NETBSD_ARCH)/binary/gzimg
NETBSD_KERNELS := $(RTBSD_DIR)/build/obj.$(NETBSD_ARCH)/sys/arch/$(NETBSD_MARCH)/compile
NETBSD_TOOLS := $(RTBSD_DIR)/build/obj.$(NETBSD_ARCH)/tooldir.$(HOST_UNAME_S)-$(HOST_UNAME_R)-$(HOST_UNAME_P)

netbsd_aarch64_image:
	@echo "Building image for NetBSD(AARCH64)"
	@cd $(NETBSD_SRC_DIR) && \
		./build.sh -U -u -j$(NETBSD_MAXJOBS) \
		-O $(RTBSD_DIR)/build/obj.$(NETBSD_ARCH) \
		-m $(NETBSD_MARCH) \
		-a $(NETBSD_ARCH) \
		release releasekernel=$(NETBSD_KERNCONFIG)
	@gunzip -d $(NETBSD_IMAGES)/arm64.img.gz
	@cp $(NETBSD_IMAGES)/arm64.img ./netbsd-aarch64.img
	@qemu-img resize ./netbsd-aarch64.img 20g

netbsd_aarch64_run:
	@echo "Run NetBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=netbsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(NETBSD_QEMU_EFI) -nographic

netbsd_aarch64_clean:
	@echo "Clean NetBSD(AARCH64)"
	@rm -rf $(RTBSD_DIR)/build/obj.$(NETBSD_ARCH)