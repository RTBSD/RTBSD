EMB3531_ATF_SRC := $(RTBSD_DIR)/platform/rk3399/open_loader/arm-trusted-firmware
EMB3531_UBOOT_SRC := $(RTBSD_DIR)/platform/rk3399/open_loader/u-boot
EMB3531_IMAGE := $(RTBSD_DIR)/emb3531.img

emb3531_setup:
	git clone https://github.com/ARM-software/arm-trusted-firmware.git \
		$(EMB3531_ATF_SRC) -b v2.7.0 && cd $(EMB3531_ATF_SRC) && git rm '*.bin'
	git clone  https://github.com/u-boot/u-boot.git \
		$(EMB3531_UBOOT_SRC) -b v2022.07
	aarch64-linux-gnu-gcc --version
	arm-none-eabi-gcc --version

emb3531_atf:
	@cd $(EMB3531_ATF_SRC) && \
		make realclean && \
		make CROSS_COMPILE=aarch64-linux-gnu- PLAT=rk3399 bl31

emb3531_uboot:
	@cd $(EMB3531_UBOOT_SRC) && \
		make mrproper && \
		make rockpro64-rk3399_defconfig && \
		make CROSS_COMPILE=aarch64-linux-gnu- -j10 \
		BL31=$(EMB3531_ATF_SRC)/build/rk3399/release/bl31/bl31.elf

emb3531_image:
	@dd if=/dev/zero of=$(EMB3531_IMAGE) bs=1M count=2048
	@sudo losetup /dev/loop0 $(EMB3531_IMAGE)
	@sudo dd if=$(EMB3531_UBOOT_SRC)/idbloader.img of=/dev/loop0p1 seek=64
	@sudo dd if=$(EMB3531_UBOOT_SRC)/u-boot.itb of=/dev/loop0p2 seek=16384
	@sudo losetup -d /dev/loop0