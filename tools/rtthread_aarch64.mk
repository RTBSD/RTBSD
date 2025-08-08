export SHELL := /bin/bash

RTTHREAD_SRC_DIR := $(RTBSD_DIR)/rtos/rt-thread

rtthread_aarch64_menuconfig:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && scons --menuconfig

rtthread_aarch64_libbsd:
	@cd $(RTBSD_DIR)/libbsd && scons -c && scons FDT=1

# execute export RTT_EXEC_PATH=$(whereis aarch64-none-elf-gcc | awk '{print $2}' | xargs dirname)
#  before run 'make rtthread_aarch64_image'
rtthread_aarch64_image:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && scons

rtthread_aarch64_run:
	@cd $(RTTHREAD_SRC_DIR)/bsp/qemu-virt64-aarch64 && ./qemu.sh

rtthread_rpi3b_menuconfig:
	@cd $(RTTHREAD_SRC_DIR)/bsp/raspberry-pi/raspi3-64 && scons --menuconfig

rtthread_rpi3b_image:
	@cd $(RTTHREAD_SRC_DIR)/bsp/raspberry-pi/raspi3-64 && scons

rtthread_rpi3b_run:
	@cd $(RTTHREAD_SRC_DIR)/bsp/raspberry-pi/raspi3-64 && ./qemu-64.sh