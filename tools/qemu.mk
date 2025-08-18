export SHELL := /bin/bash

QEMU_SRC_PATH := $(RTBSD_DIR)/tools/qemu

qemu_aarch64_tools:
	@mkdir -p $(RTBSD_DIR)/build/qemu
	@cd $(RTBSD_DIR)/build/qemu && \
		$(QEMU_SRC_PATH)/configure \
			--target-list=aarch64-softmmu \
			--prefix=$(QEMU_TOOL_PATH) \
			--enable-debug \
			--enable-kvm && \
		make -j && \
		make install

qemu_aarch64_info:
	@$(QEMU_TOOL_PATH)/bin/qemu-system-aarch64 --machine help
	@$(QEMU_TOOL_PATH)/bin/qemu-system-aarch64 --device help
	@$(QEMU_TOOL_PATH)/bin/qemu-system-aarch64 --cpu help
	@$(QEMU_TOOL_PATH)/bin/qemu-system-aarch64 --version