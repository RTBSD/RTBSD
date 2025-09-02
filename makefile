export RTBSD_DIR := $(realpath $(CURDIR))
export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p

include $(RTBSD_DIR)/tools/freebsd.mk
include $(RTBSD_DIR)/tools/netbsd.mk
include $(RTBSD_DIR)/tools/libbsd.mk