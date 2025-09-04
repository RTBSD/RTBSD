export SHELL := /bin/bash

LIBBSD_BUILD_DIR := $(RTBSD_DIR)/build/libbsd

libbsd_fdt_aarch64:
	@mkdir -p $(LIBBSD_BUILD_DIR)
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 FDT=1 GDBSTUB=1 PCI=1\
		OBJDIR=$(LIBBSD_BUILD_DIR) all

libbsd_acpi_aarch64:
	@mkdir -p $(LIBBSD_BUILD_DIR)
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 ACPI=1 GDBSTUB=1 PCI=1\
		OBJDIR=$(LIBBSD_BUILD_DIR) all

libbsd_clean:
	@rm $(LIBBSD_BUILD_DIR) -rf