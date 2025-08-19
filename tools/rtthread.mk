export SHELL := /bin/bash

RTTHREAD_SRC_DIR := $(RTBSD_DIR)/rtos/rt-thread

rtthread_aarch64_menuconfig:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && scons --menuconfig

# execute export RTT_EXEC_PATH=$(whereis aarch64-none-elf-gcc | awk '{print $2}' | xargs dirname)
#  before run 'make rtthread_aarch64_image'
rtthread_aarch64_image:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && scons

rtthread_aarch64_run:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && ./qemu.sh