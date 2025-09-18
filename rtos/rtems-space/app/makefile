#
#  RTEMS_MAKEFILE_PATH is typically set in an environment variable
#

PGM=${ARCH}/rtems.exe

# C source names
CSRCS =  main.c posix_main.c
COBJS = $(CSRCS:%.c=${ARCH}/%.o)

# Libraries
LIBS =

include $(RTEMS_MAKEFILE_PATH)/Makefile.inc
include $(RTEMS_CUSTOM)
include $(PROJECT_ROOT)/make/leaf.cfg

OBJS= $(COBJS) $(CXXOBJS) $(ASOBJS)

define bsp-link-c
	$(LINK.c) $(CPU_CFLAGS) $(AM_CFLAGS) $(AM_LDFLAGS) \
	    -o $(basename $@)$(EXEEXT) $(LINK_OBJS) $(LINK_LIBS) \
		-Wl,-Map,"$(basename $@).map"
endef

define bsp-link-cxx
	$(LINK.cc) $(CPU_CFLAGS) $(AM_CFLAGS) $(AM_LDFLAGS) \
	    -o $(basename $@)$(EXEEXT) $(LINK_OBJS) $(LINK_LIBS) \
		-Wl,-Map,"$(basename $@).map"
endef

define default-bsp-post-link
	$(RTEMS_CPU)-rtems$(RTEMS_API)-objdump -D $@ > $(basename $@).asm
	$(SIZE) $@
endef

subdir:
	@mkdir -p ${ARCH}/src

all: subdir ${ARCH} $(PGM)
	@echo "BSP: $(RTEMS_MAKEFILE_PATH)"

ifeq ($(OS),Windows_NT)
USR_BOOT_DIR		?= D:\\tftpboot
else
USR_BOOT_DIR		?= /mnt/d/tftpboot
endif

image: all
	@cp ${PGM} $(USR_BOOT_DIR)/rtems.exe -f
	@$(OBJCOPY) -O binary ${USR_BOOT_DIR}/rtems.exe ${USR_BOOT_DIR}/rtems.bin
	@ls $(USR_BOOT_DIR)/rtems.* -lh

# override with cxx linker
$(PGM): $(OBJS)
	$(make-cxx-exe)