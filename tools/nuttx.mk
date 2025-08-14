export SHELL := /bin/bash

NUTTX_BUILD_DIR := $(RTBSD_DIR)/build/nuttx
NUTTX_SRC_DIR := $(RTBSD_DIR)/rtos/nuttxspace

nuttx_list:
	@cd $(NUTTX_SRC_DIR)/nuttx && \
		./tools/configure.sh -L

nuttx_aarch64_config:
	@cd $(NUTTX_SRC_DIR)/nuttx && \
		./tools/configure.sh -l qemu-armv8a:nsh
	@cd $(NUTTX_SRC_DIR)/nuttx && \
		make menuconfig

nuttx_image:
	@cd $(NUTTX_SRC_DIR)/nuttx && make -j

nuttx_clean:
	@cd $(NUTTX_SRC_DIR)/nuttx && make clean

nuttx_aarch64_run:
	@cp $(NUTTX_SRC_DIR)/nuttx/nuttx ./nuttx.img -f
	@qemu-system-aarch64 -cpu cortex-a53 -nographic \
		-machine virt,virtualization=on,gic-version=3 \
		-net none -chardev stdio,id=con,mux=on -serial chardev:con \
		-mon chardev=con,mode=readline -kernel ./nuttx.img