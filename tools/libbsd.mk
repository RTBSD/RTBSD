export SHELL := /bin/bash

LIBBSD_BUILD_DIR := $(RTBSD_DIR)/build/libbsd

libbsd_fdt_aarch64:
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 FDT=1 GDBSTUB=1 OBJDIR=$(LIBBSD_BUILD_DIR) all

libbsd_acpi_aarch64:
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 ACPI=1 GDBSTUB=1 OBJDIR=$(LIBBSD_BUILD_DIR) all

libbsd_fdt_aarch64_clean:
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 FDT=1 GDBSTUB=1 OBJDIR=$(LIBBSD_BUILD_DIR) clean

libbsd_acpi_aarch64_clean:
	@cd $(RTBSD_DIR)/libbsd && \
		make -f makefile.gcc.aarch64 \
		AARCH64=1 ACPI=1 GDBSTUB=1 OBJDIR=$(LIBBSD_BUILD_DIR) clean