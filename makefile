export RTBSD_DIR := $(realpath $(CURDIR))
export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p

include $(RTBSD_DIR)/tools/freebsd_aarch64.mk
include $(RTBSD_DIR)/tools/freebsd_amd64.mk
include $(RTBSD_DIR)/tools/freebsd_riscv64.mk
include $(RTBSD_DIR)/tools/netbsd_aarch64.mk
include $(RTBSD_DIR)/tools/netbsd_amd64.mk
include $(RTBSD_DIR)/tools/netbsd_riscv64.mk
include $(RTBSD_DIR)/tools/rtthread_aarch64.mk
include $(RTBSD_DIR)/tools/baremetal_raspi3.mk

qemu_aarch64_info:
	@qemu-system-aarch64 --machine help
	@qemu-system-aarch64 --device help
	@qemu-system-aarch64 --cpu help
	@qemu-system-aarch64 --version