if [ -d "$1" ]; then
	rm -rf "$1"
fi
mkdir -p $1
PKBUILDDIR=`readlink -f $1`
PKROOT=`pwd`
cd ${PKBUILDDIR} && ${PKROOT}/configure \
        --host=riscv64-unknown-elf \
        --with-payload=$2 \
        --enable-logo \
        --enable-dts \
        --with-logo=${PKROOT}/shakti_logo.txt \
        --with-target-isa=rv64imafd \
        --with-target-abi=lp64d \
        --enable-print-device-tree
make -C ${PKBUILDDIR} -j32
