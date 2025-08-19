export RTBSD_DIR := $(realpath $(CURDIR))
export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p
export QEMU_TOOL_PATH := $(RTBSD_DIR)/build/output/qemu
export QEMU_BIN_PATH := $(QEMU_TOOL_PATH)/bin

include $(RTBSD_DIR)/tools/qemu.mk
include $(RTBSD_DIR)/tools/freebsd.mk
include $(RTBSD_DIR)/tools/netbsd.mk
include $(RTBSD_DIR)/tools/libbsd.mk
include $(RTBSD_DIR)/tools/rtthread.mk
include $(RTBSD_DIR)/tools/baremetal_raspi3.mk
include $(RTBSD_DIR)/tools/rtems.mk
include $(RTBSD_DIR)/tools/nuttx.mk