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

llvm_x86_64_debian_toolchain:
	@if [ ! -f "clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" ]; then \
		@wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz; \
	fi
	@mkdir -p $(RTBSD_DIR)/tools/llvm-x86_64
	@tar -xvf clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
		-C $(RTBSD_DIR)/tools/llvm-x86_64 \
		 --strip-components=1
	@mkdir -p $(RTBSD_DIR)/build 
	@mkdir -p $(RTBSD_DIR)/build/output
	@ln -s $(RTBSD_DIR)/tools/llvm-x86_64 $(RTBSD_DIR)/build/output/upstream-llvm
	@echo "Setup x86_64 LLVM tools"

qemu_aarch64_info:
	@qemu-system-aarch64 --machine help
	@qemu-system-aarch64 --device help
	@qemu-system-aarch64 --cpu help
	@qemu-system-aarch64 --version