export SHELL := /bin/bash

scons_libbsd_fdt_aarch64:
	@cd $(RTBSD_DIR)/libbsd && scons AARCH64=1 FDT=1 GDBSTUB=1

scons_libbsd_fdt_aarch64_clean:
	@cd $(RTBSD_DIR)/libbsd && scons -c AARCH64=1 FDT=1 GDBSTUB=1