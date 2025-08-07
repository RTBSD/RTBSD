export SHELL := /bin/bash

OPENBSD_MARCH := evbarm
OPENBSD_ARCH := aarch64
OPENBSD_KERNCONFIG := GENERIC64
OPENBSD_MAXJOBS := 12
OPENBSD_SRC_DIR := $(RTBSD_DIR)/upstream/openbsd
OPENBSD_QEMU_EFI := /usr/share/qemu-efi-aarch64/QEMU_EFI.fd

openbsd_aarch64_qemu_setup:
	@wget https://jp2.dl.fuguita.org/LiveSD/FuguIta-7.7-arm64-202507011.img.gz
	@gzip -d FuguIta-7.7-arm64-202507011.img.gz

openbsd_aarch64_qemu_build:
	@echo "Build for OpenBSD(AARCH64)"
	@qemu-system-aarch64 -M virt -cpu cortex-a53 -smp 4 -m 8g \
		-drive if=none,file=FuguIta-7.7-arm64-202507011.img,format=raw,id=hd0 -device virtio-blk-device,drive=hd0  \
		-drive if=none,file=openbsd-aarch64.qcow2,format=qcow2,id=hd1 -device virtio-blk-device,drive=hd1  \
		-netdev type=user,id=net0 -device virtio-net-device,netdev=net0,mac=00:11:22:33:44:55 \
		-bios $(OPENBSD_QEMU_EFI) -nographic