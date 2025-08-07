#!/bin/bash

git clone https://github.com/RTBSD/LibBSD.git -b main ./libbsd
git clone https://github.com/RTBSD/cheribuild.git -b main ./tools/cheribuild
git clone https://github.com/RTBSD/freebsd-src.git -b releng/14.3 ./upstream/freebsd --depth=1
git clone https://github.com/RTBSD/NetBSD-src.git -b netbsd-10 ./upstream/netbsd --depth=1
git clone https://github.com/RTBSD/rt-thread.git -b master ./rtos/rt-thread --depth=1
