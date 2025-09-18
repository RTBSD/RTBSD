#!/bin/bash

export PATH=${RTEMS_TOOLCHAIN_PATH}/bin:${PATH}

echo "RTEMS Tool: ${RTEMS_TOOLCHAIN_PATH}"
echo "RTEMS BSP: ${RTEMS_MAKEFILE_PATH}"

echo "Environment setup done !!!"
echo "  ./waf to build all examples with wscript"
echo "  make all to build all examples with makefile"
echo "  cd to specific example path and ./waf or make to build"
