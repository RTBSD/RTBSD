#!/bin/bash

echo "Setup RTEMS tools for FireflyV2 ..."

export RTEMS_BSP=aarch64/firefly_v2
export RTEMS_MAKEFILE_PATH=$(realpath ./build/rtems/toolchain/aarch64-6/aarch64-rtems6/firefly_v2)
export RTEMS_TOOLCHAIN_PATH=$(realpath ./build/rtems/toolchain/aarch64-6)
export RTEMS_TOOL_PATH_PREFIX=${RTEMS_TOOLCHAIN_PATH}/bin/aarch64-rtems6-
export RTEMS_TFTP_PATH=$(realpath /mnt/d/tftpboot)

source ./rtos/rtems-space/env/image_ops.sh