export RTBSD_DIR := $(realpath $(CURDIR))
export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p

include $(RTBSD_DIR)/tools/freebsd.mk
include $(RTBSD_DIR)/tools/netbsd.mk
include $(RTBSD_DIR)/tools/libbsd.mk
include $(RTBSD_DIR)/tools/rtems.mk
include $(RTBSD_DIR)/tools/haiku.mk
include $(RTBSD_DIR)/platform/rockpro64/rk3399_rockpro64.mk
include $(RTBSD_DIR)/platform/toybrick/rk3399_toybrick.mk