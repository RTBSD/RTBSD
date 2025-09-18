#!/bin/bash

git clone https://github.com/RTBSD/LibBSD.git -b main ./libbsd
git clone https://github.com/RTBSD/cheribuild.git -b firefly ./tools/cheribuild
git clone https://github.com/RTBSD/freebsd-src.git -b firefly ./upstream/freebsd --depth=1
git clone https://github.com/RTBSD/NetBSD-src.git -b firefly ./upstream/netbsd --depth=1
