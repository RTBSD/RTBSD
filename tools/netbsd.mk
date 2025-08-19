export SHELL := /bin/bash

NETBSD_AARCH64_MARCH := evbarm
NETBSD_AARCH64_ARCH := aarch64
NETBSD_AARCH64_KERNCONFIG := GENERIC64
NETBSD_AARCH64_MAXJOBS := 12
NETBSD_AARCH64_SRC_DIR := $(RTBSD_DIR)/upstream/netbsd
NETBSD_AARCH64_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
NETBSD_AARCH64_IMAGES := $(RTBSD_DIR)/build/obj.$(NETBSD_AARCH64_ARCH)/releasedir/$(NETBSD_AARCH64_MARCH)-$(NETBSD_AARCH64_ARCH)/binary/gzimg
NETBSD_AARCH64_KERNELS := $(RTBSD_DIR)/build/obj.$(NETBSD_AARCH64_ARCH)/sys/arch/$(NETBSD_AARCH64_MARCH)/compile
NETBSD_AARCH64_TOOLS := $(RTBSD_DIR)/build/obj.$(NETBSD_AARCH64_ARCH)/tooldir.$(HOST_UNAME_S)-$(HOST_UNAME_R)-$(HOST_UNAME_P)

netbsd_aarch64_image:
	@echo "Building image for NetBSD(AARCH64)"
	@cd $(NETBSD_AARCH64_SRC_DIR) && \
		./build.sh -U -u -j$(NETBSD_AARCH64_MAXJOBS) \
		-O $(RTBSD_DIR)/build/obj.$(NETBSD_AARCH64_ARCH) \
		-m $(NETBSD_AARCH64_MARCH) \
		-a $(NETBSD_AARCH64_ARCH) \
		tools release \
		releasekernel=$(NETBSD_AARCH64_KERNCONFIG)
	@gunzip -d $(NETBSD_AARCH64_IMAGES)/arm64.img.gz
	@cp $(NETBSD_AARCH64_IMAGES)/arm64.img ./netbsd-aarch64.img
	@qemu-img resize ./netbsd-aarch64.img 20g

netbsd_aarch64_run:
	@echo "Run NetBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=netbsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(NETBSD_AARCH64_QEMU_EFI) -nographic

# Boot NetBSD from firefly pi U-boot
# 	usb start;
#	fatload usb 0:1 0x90100000 /efi/boot/bootaa64.efi;
#	fatload usb 0:1 0xa0000000 /dtb/firefly/firefly_pi_v2.dtb;
#	bootefi 0x90100000 0xa0000000
#   boot with gdb: boot -d, gdb
#   sysctl debug.kdb.enter=1, gdb
netbsd_firefly_attach:
	@echo "Attach NetBSD(AARCH64) in debug mode"

netbsd_aarch64_clean:
	@echo "Clean NetBSD(AARCH64)"
	@rm -rf $(RTBSD_DIR)/build/obj.$(NETBSD_AARCH64_ARCH)

NETBSD_AMD64_MARCH := amd64
NETBSD_AMD64_KERNCONFIG := GENERIC
NETBSD_AMD64_MAXJOBS := 12
NETBSD_AMD64_SRC_DIR := $(RTBSD_DIR)/upstream/netbsd
NETBSD_AMD64_QEMU_EFI_AMD64 := /usr/share/OVMF/OVMF_CODE.fd
NETBSD_AMD64_IMAGES := $(RTBSD_DIR)/build/obj.$(NETBSD_AMD64_MARCH)/releasedir/images

netbsd_amd64_image:
	@echo "Building image for NetBSD(AMD64)"
	@cd $(NETBSD_AMD64_SRC_DIR) && \
		./build.sh -U -u -j$(NETBSD_AMD64_MAXJOBS) \
		-m $(NETBSD_AMD64_MARCH) \
		-O $(RTBSD_DIR)/build/obj.$(NETBSD_AMD64_MARCH) \
		tools \
		releasekernel=$(NETBSD_AMD64_KERNCONFIG) \
		release live-image
	@gunzip -d $(NETBSD_AMD64_IMAGES)/NetBSD-10.1_STABLE-amd64-live.img.gz
	@cp $(NETBSD_AMD64_IMAGES)/NetBSD-10.1_STABLE-amd64-live.img ./netbsd-amd64.img
	@chmod +x ./netbsd-amd64.img
	@qemu-img resize ./netbsd-amd64.img 20g

netbsd_amd64_run:
	@echo "Run NetBSD(AMD64)"
	qemu-system-x86_64 -m 2048 -smp 2 \
		-hda netbsd-amd64.img \
		-nographic

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