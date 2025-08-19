export SHELL := /bin/bash

libbsd_fdt_aarch64:
	@cd $(RTBSD_DIR)/libbsd && make -f makefile.gcc.aarch64 AARCH64=1 FDT=1 GDBSTUB=1 all

libbsd_acpi_aarch64:
	@cd $(RTBSD_DIR)/libbsd && make -f makefile.gcc.aarch64 AARCH64=1 ACPI=1 GDBSTUB=1 all

libbsd_fdt_aarch64_clean:
	@cd $(RTBSD_DIR)/libbsd && make -f makefile.gcc.aarch64 AARCH64=1 FDT=1 GDBSTUB=1 clean

libbsd_acpi_aarch64_clean:
	@cd $(RTBSD_DIR)/libbsd && make -f makefile.gcc.aarch64 AARCH64=1 ACPI=1 GDBSTUB=1 clean