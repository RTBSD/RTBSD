export SHELL := /bin/bash

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
		tools release live-image \
		disk-image=amd64 \
		releasekernel=$(NETBSD_AMD64_KERNCONFIG)
	@gunzip -d $(NETBSD_AMD64_IMAGES)/NetBSD-10.1_STABLE-amd64-live.img.gz
	@cp $(NETBSD_AMD64_IMAGES)/NetBSD-10.1_STABLE-amd64-live.img ./netbsd-amd64.img
	@chmod +x ./netbsd-amd64.img
	@qemu-img resize ./netbsd-amd64.img 20g