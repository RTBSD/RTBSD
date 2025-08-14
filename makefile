export RTBSD_DIR := $(realpath $(CURDIR))
export HOST_UNAME_S!=  uname -s
export HOST_UNAME_R!=  uname -r
export HOST_UNAME_P!=  uname -p

include $(RTBSD_DIR)/tools/freebsd.mk
include $(RTBSD_DIR)/tools/netbsd.mk
include $(RTBSD_DIR)/tools/rtthread.mk
include $(RTBSD_DIR)/tools/baremetal_raspi3.mk
include $(RTBSD_DIR)/tools/rtems.mk
include $(RTBSD_DIR)/tools/nuttx.mk

llvm_x86_64_debian_toolchain:
	@if [ ! -f "clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz" ]; then \
		@wget https://github.com/llvm/llvm-project/releases/download/llvmorg-18.1.8/clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz; \
	fi
	@mkdir -p $(RTBSD_DIR)/build/output/upstream-llvm
	@tar -xvf clang+llvm-18.1.8-x86_64-linux-gnu-ubuntu-18.04.tar.xz \
		-C $(RTBSD_DIR)/build/output/upstream-llvm \
		 --strip-components=1
	@echo "Setup x86_64 LLVM tools"

freebsd_clean:
	@echo "Clean FreeBSD(AARCH64/AMD64/Risv64)"
	@rm -rf $(RTBSD_DIR)/build/freebsd-aarch64-build
	@rm -rf $(RTBSD_DIR)/build/freebsd-amd64-build
	@rm -rf $(RTBSD_DIR)/build/freebsd-riscv64-build
	@rm -rf $(RTBSD_DIR)/build/output
	@rm -rf $(RTBSD_DIR)/build/extra-files

qemu_aarch64_info:
	@qemu-system-aarch64 --machine help
	@qemu-system-aarch64 --device help
	@qemu-system-aarch64 --cpu help
	@qemu-system-aarch64 --version