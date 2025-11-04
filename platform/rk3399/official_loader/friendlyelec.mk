FRIENDLYELEC_SD_FUSB_SRC := $(RTBSD_DIR)/platform/rk3399/official_loader/sd-fuse_rk3399

friendlyelec_setup:
	git clone https://github.com/friendlyarm/sd-fuse_rk3399.git $(FRIENDLYELEC_SD_FUSB_SRC) -b kernel-4.19
	git clone https://github.com/friendlyarm/uboot-rockchip --depth 1 -b nanopi4-v2017.09 $(FRIENDLYELEC_SD_FUSB_SRC)/uboot-rockchip
	git clone https://github.com/friendlyarm/kernel-rockchip --depth 1 -b nanopi4-v4.19.y $(FRIENDLYELEC_SD_FUSB_SRC)/kernel-rk3399
	cp friendlycore-focal-arm64-images.tgz $(FRIENDLYELEC_SD_FUSB_SRC)

friendlyelec_uboot:
	cd $(FRIENDLYELEC_SD_FUSB_SRC) && \
		UBOOT_SRC=$(FRIENDLYELEC_SD_FUSB_SRC)/uboot-rockchip ./build-uboot.sh friendlycore-focal-arm64

friendlyelec_kernel:
	cd $(FRIENDLYELEC_SD_FUSB_SRC) && \
		tar xvzf friendlycore-focal-arm64-images.tgz && \
		KERNEL_SRC=$(FRIENDLYELEC_SD_FUSB_SRC)/kernel-rk3399 ./build-kernel.sh friendlycore-focal-arm64 && \
		MK_HEADERS_DEB=1 BUILD_THIRD_PARTY_DRIVER=0 KERNEL_SRC=$(FRIENDLYELEC_SD_FUSB_SRC)/kernel-rk3399 ./build-kernel.sh friendlycore-focal-arm64

friendlyelec_image:
	cd $(FRIENDLYELEC_SD_FUSB_SRC) && \
		./mk-sd-image.sh friendlycore-focal-arm64