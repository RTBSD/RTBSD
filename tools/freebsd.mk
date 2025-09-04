export SHELL := /bin/bash

FREEBSD_IMAGE_DIR := /mnt/d/tftpboot

FRREEBSD_AARCH64_VERSION := 14.3
FRREEBSD_AARCH64_TARGET := arm64
FRREEBSD_AARCH64_AARCH := aarch64
FRREEBSD_AARCH64_KERNCONFIG := GENERIC-DEBUG
FRREEBSD_AARCH64_KERNDEBUG := --freebsd-with-default-options/debug-kernel
FRREEBSD_AARCH64_VERBOSE :=
FRREEBSD_AARCH64_ROOTFS := ufs
FRREEBSD_AARCH64_HOSTNAME := rtbsd
FRREEBSD_AARCH64_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
FRREEBSD_AARCH64_SRC_DIR := $(RTBSD_DIR)/upstream/freebsd
FRREEBSD_AARCH64_ROOTFS_DIR := $(RTBSD_DIR)/build/freebsd-aarch64-build$(RTBSD_DIR)/upstream/freebsd/arm64.aarch64/sys/$(FRREEBSD_AARCH64_KERNCONFIG)

llvm_x86_64_debian_toolchain:
	@if [ ! -f "clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" ]; then \
		wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz; \
	fi
	@mkdir -p $(RTBSD_DIR)/build/output/upstream-llvm
	@tar -xvf clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
		-C $(RTBSD_DIR)/build/output/upstream-llvm \
		 --strip-components=1
	@echo "Setup x86_64 LLVM tools"

freebsd_aarch64_image:
	@echo "Building image for FreeBSD(AARCH64)"
	$(RTBSD_DIR)/tools/cheribuild/cheribuild.py freebsd-aarch64 disk-image-freebsd-aarch64 \
		$(FRREEBSD_AARCH64_KERNDEBUG) \
		--kernel-config $(FRREEBSD_AARCH64_KERNCONFIG) \
		--source-root $(RTBSD_DIR)/upstream \
		--output-root $(RTBSD_DIR)/build/output \
		--build-root $(RTBSD_DIR)/build \
		--freebsd/toolchain upstream-llvm \
		--disk-image-freebsd/extra-files $(RTBSD_DIR)/build/extra-files \
		--disk-image-freebsd/hostname $(FRREEBSD_AARCH64_HOSTNAME) \
		--disk-image-freebsd/rootfs-type $(FRREEBSD_AARCH64_ROOTFS) \
		--skip-update \
		$(FRREEBSD_AARCH64_VERBOSE)
	@cp $(RTBSD_DIR)/build/output/freebsd-aarch64.img . -f
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel $(FREEBSD_IMAGE_DIR)/kernel -f
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel.debug $(FREEBSD_IMAGE_DIR)/kernel.debug -f
#	@qemu-img resize freebsd-aarch64.img 4G

freebsd_aarch64_run:
	@echo "Run FreeBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(FRREEBSD_AARCH64_QEMU_EFI) -nographic

# setup nameserver after bootup
# 	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
# 	echo "nameserver 8.8.4.4" >> /etc/resolv.conf
freebsd_aarch64_net_run:
	@echo "Run FreeBSD(AARCH64) with Network"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev user,id=net0,hostfwd=tcp::2222-:22 \
		-device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(FRREEBSD_AARCH64_QEMU_EFI) -nographic

freebsd_aarch64_pci_run:
	@echo "Run FreeBSD(AARCH64) with PCIe"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-device pci-bridge,chassis_nr=1,id=pci-bridge-1,bus=pcie.0,addr=0x1 \
		-device qemu-xhci,id=xhci,bus=pci-bridge-1,addr=0x1 \
		-device usb-hub,bus=xhci.0,port=1 \
		-device usb-kbd,bus=xhci.0,port=1.1 \
		-bios $(FRREEBSD_AARCH64_QEMU_EFI) -nographic

freebsd_aarch64_xhci_run:
	@echo "Run FreeBSD(AARCH64) with XHCI"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-device qemu-xhci,id=xhci \
		-device usb-hub,bus=xhci.0,port=1 \
		-device usb-kbd,bus=xhci.0,port=1.1 \
		-bios $(FRREEBSD_AARCH64_QEMU_EFI) -nographic

freebsd_aarch64_debug:
	@echo "Run FreeBSD(AARCH64) in debug mode"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 4g \
		-drive if=none,file=freebsd-aarch64.img,id=hd0 -device virtio-blk-device,drive=hd0 \
		-device pci-bridge,chassis_nr=1,id=pci-bridge-1,bus=pcie.0,addr=0x1 \
		-device qemu-xhci,id=xhci,bus=pci-bridge-1,addr=0x1 \
		-device usb-hub,bus=xhci.0,port=1 \
		-device usb-kbd,bus=xhci.0,port=1.1 \
		-bios $(FRREEBSD_AARCH64_QEMU_EFI) -nographic \
		-s -S

freebsd_aarch64_attach:
	@echo "Attach FreeBSD(AARCH64) in debug mode"
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel kernel -f
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel.debug kernel.debug -f
	@gdb-multiarch -x ./tools/.gdbinit.freebsd.aarch64

# Boot FreeBSD from firefly pi U-boot
# 	usb start;
#	fatload usb 0:1 0x90100000 /efi/boot/bootaa64.efi;
#	fatload usb 0:1 0xa0000000 /efi/boot/firefly_pi_v2.dtb;
#	bootefi 0x90100000 0xa0000000
#   boot with gdb: boot -d, gdb
#   sysctl debug.kdb.enter=1, gdb

# Boot FreeBSD from firefly dsk v1 U-boot
#	fatload scsi 0:1 0x90100000 /efi/boot/bootaa64.efi;
#	fatload scsi 0:1 0xa0000000 /efi/boot/firefly_dsk_v1.dtb;
#	bootefi 0x90100000 0xa0000000

# Boot FreeBSD from firefly dsk v3 U-boot
#	fatload scsi 0:1 0x90100000 /efi/boot/bootaa64.efi;
#	fatload scsi 0:1 0xa0000000 /efi/boot/firefly_dsk_v3.dtb;
#	bootefi 0x90100000 0xa0000000
freebsd_firefly_attach:
	@echo "Attach FreeBSD(AARCH64) in debug mode"
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel kernel -f
	@cp $(FRREEBSD_AARCH64_ROOTFS_DIR)/kernel.debug kernel.debug -f
	@gdb-multiarch -x ./tools/.gdbinit.freebsd.firefly

FRREEBSD_AMD64_VERSION := 14.3
FRREEBSD_AMD64_TARGET := amd64
FRREEBSD_AMD64_AARCH := amd64
FRREEBSD_AMD64_KERNCONFIG := GENERIC-DEBUG
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
		$(FRREEBSD_AMD64_KERNDEBUG) \
		--kernel-config $(FRREEBSD_AMD64_KERNCONFIG) \
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

FRREEBSD_RISCV64_VERSION := 14.3
FRREEBSD_RISCV64_TARGET := riscv
FRREEBSD_RISCV64_AARCH := riscv64
FRREEBSD_RISCV64_KERNCONFIG := GENERIC-DEBUG
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
		$(FRREEBSD_RISCV64_KERNDEBUG) \
		--kernel-config $(FRREEBSD_RISCV64_KERNCONFIG) \
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

freebsd_clean:
	@echo "Clean FreeBSD(AARCH64/AMD64/Risv64)"
	@rm -rf $(RTBSD_DIR)/build/freebsd-aarch64-build
	@rm -rf $(RTBSD_DIR)/build/freebsd-amd64-build
	@rm -rf $(RTBSD_DIR)/build/freebsd-riscv64-build
	@rm -rf $(RTBSD_DIR)/build/output
	@rm -rf $(RTBSD_DIR)/build/extra-files