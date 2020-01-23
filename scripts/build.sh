#!/bin/bash

set -e

. bsp/conf/shakti.config

#
# test environment
#
for var in ARCH ABI CROSS_COMPILE BUSYBOX_VERSION \
    DROPBEAR_VERSION LINUX_KERNEL_VERSION; do
    if [ -z "${!var}" ]; then
        echo "${!var} not set" && exit 1
    fi
done

#
# find executables
#
for prog in ${CROSS_COMPILE}gcc sudo nproc curl openssl rsync; do
    if [ -z $(which ${prog}) ]; then
        echo "error: ${prog} not found in PATH" && exit 1
    fi
done

#
# download busybox, dropbear 
#
export MAKEFLAGS=-j4
test -d archives || mkdir archives
test -f archives/busybox-${BUSYBOX_VERSION}.tar.bz2 || \
    curl -L -o archives/busybox-${BUSYBOX_VERSION}.tar.bz2 \
        https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
test -f archives/dropbear-${DROPBEAR_VERSION}.tar.bz2 || \
    curl -L -o archives/dropbear-${DROPBEAR_VERSION}.tar.bz2 \
        https://matt.ucc.asn.au/dropbear/releases/dropbear-${DROPBEAR_VERSION}.tar.bz2

#
# extract busybox, dropbear 
#
test -d build || mkdir build
test -d build/busybox-${BUSYBOX_VERSION} || \
    tar -C build -xjf archives/busybox-${BUSYBOX_VERSION}.tar.bz2
test -d build/dropbear-${DROPBEAR_VERSION} || \
    tar -C build -xjf archives/dropbear-${DROPBEAR_VERSION}.tar.bz2

#
# set default configurations
#
cp bsp/conf/busybox.config build/busybox-${BUSYBOX_VERSION}/.config
cp bsp/conf/shakti_defconfig build/linux-${LINUX_KERNEL_VERSION}/.config

#
# build busybox, dropbear and linux
#
test -x build/busybox-${BUSYBOX_VERSION}/busybox || (
    cd build/busybox-${BUSYBOX_VERSION}
    make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} oldconfig
    make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} -j$(nproc)
)
test -x build/dropbear-${DROPBEAR_VERSION}/dropbear || (
    cd build/dropbear-${DROPBEAR_VERSION}
    ./configure --host=${CROSS_COMPILE%-} --disable-zlib
    make -j$(nproc)
)
test -x build/linux-${LINUX_KERNEL_VERSION}/vmlinux || (
    cd build/linux-${LINUX_KERNEL_VERSION}
    make ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} olddefconfig
    make -j$(nproc) ARCH=riscv CROSS_COMPILE=${CROSS_COMPILE} vmlinux
)

#
# build bbl
#
test -d build/riscv-pk || mkdir build/riscv-pk
test -x build/riscv-pk/bbl || ./scripts/build.sh

#
# create filesystem image
#
sudo env PATH=${PATH} UID=$(id -u) GID=$(id -g) \
./scripts/image.sh
