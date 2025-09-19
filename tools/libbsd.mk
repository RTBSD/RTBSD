export SHELL := /bin/bash

LIBBSD_BUILD_DIR := $(RTBSD_DIR)/build/libbsd
LIBBSD_OPTION ?=

libbsd_aarch64:
	@mkdir -p $(LIBBSD_BUILD_DIR)
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.aarch64 \
		$(LIBBSD_OPTION) \
		OBJDIR=$(LIBBSD_BUILD_DIR) all -j

libbsd_clean:
	@rm $(LIBBSD_BUILD_DIR) -rf