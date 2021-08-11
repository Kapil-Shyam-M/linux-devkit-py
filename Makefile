#########################################################################
#  Project           		 : 	Linux Development kit for Shakti Boards #
#  Name of the file	     	 :  Makefile
#  Brief Description of file : Makefile to build the linux port to Shakti C class.
#  Modified for SHAKTI       : John Jacob
#  Email ID                  :   
#                                                                       #
#                                                                       #
#########################################################################

# ToDo Add license from freedom u sdk and shakti license

####################Features ############################################
#                                                                       #
# 	1. Build Linux for Specific SOC [ Linux Version 5.1(Stable)]    #
#       2. Added Support for Building with desired Bootloader           #
#		-Proxy Kernel                                           #
#		-OpenSBI                                                #
#		-U-Boot                                                 #
#                                                                       #
#########################################################################	

RISCV ?=/opt/riscv
PATH := $(RISCV)/bin:$(PATH)
ISA ?= rv64imac
ABI ?= lp64

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
confdir := $(srcdir)/bsp/conf
wrkdir := $(CURDIR)/work
bloaddir :=$(srcdir)/bootloaders
##### BUILDROOT RELATED CONFIGS ################################################
buildroot_srcdir := $(srcdir)/buildroot                           
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs
buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_config := $(confdir)/buildroot_initramfs_config
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot
buildroot_rootfs_wrkdir := $(wrkdir)/buildroot_rootfs
buildroot_rootfs_ext := $(buildroot_rootfs_wrkdir)/images/rootfs.ext4
buildroot_rootfs_config := $(confdir)/buildroot_rootfs_config
##############################################################################

###### U-BOOT RELATED CONFIGS ##################################################
uboot_config:=shakti_uboot_defconfig
uboot_dir:=$(bloaddir)/uboot
uboot_wrkdir:=$(wrkdir)/uboot
uboot_bin:=$(uboot_wrkdir)/uboot.bin
################################################################################

######## LINUX RELATED CONFIGS #################################################
linux_srcdir := $(srcdir)/linux-on-shakti
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/shakti_defconfig
vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
###############################################################################

######## Proxy Kernel(BBL) RELATED CONFIGS ####################################
pk_srcdir := $(srcdir)/bootloaders/riscv-pk
pk_wrkdir := $(wrkdir)/riscv-pk
bbl := $(pk_wrkdir)/bbl
bin := $(wrkdir)/bbl.bin
hex := $(wrkdir)/bbl.hex
##############################################################################

######### OpenSBI RELATED CONFIGS ############################################
opensbi_dir :=$(srcdir)/bootloaders/shakti-opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
#############################################################################


rootfs := $(wrkdir)/rootfs.bin

target := riscv64-unknown-linux-gnu
btarget := riscv64-unknown-elf-
.PHONY: all
#all: $(hex)
#	@echo
#	@echo This image has been generated for an ISA of $(ISA) and an ABI of $(ABI)
#	@echo Find the SD-card image in work/bbl.bin
#	@echo Program it with: dd if=work/bbl.bin of=/dev/sd-your-card bs=1M
#	@echo Supports Boards XXX with XXXX core.	
	@echo "Generated BBL for a core of $(ISA) with  $(ABI)"

$(buildroot_initramfs_wrkdir)/.config: $(buildroot_srcdir)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_initramfs_config) $@
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir) olddefconfig

$(buildroot_initramfs_tar): $(buildroot_srcdir) $(buildroot_initramfs_wrkdir)/.config $(RISCV)/bin/$(target)-gcc $(buildroot_initramfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_initramfs_wrkdir)

.PHONY: buildroot_initramfs-menuconfig
buildroot_initramfs-menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig conf/buildroot_initramfs_config

$(buildroot_rootfs_wrkdir)/.config: $(buildroot_srcdir)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_rootfs_config) $@
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir) olddefconfig

$(buildroot_rootfs_ext): $(buildroot_srcdir) $(buildroot_rootfs_wrkdir)/.config $(RISCV)/bin/$(target)-gcc $(buildroot_rootfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) PATH=$(PATH) O=$(buildroot_rootfs_wrkdir)

.PHONY: buildroot_rootfs-menuconfig
buildroot_rootfs-menuconfig: $(buildroot_rootfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_rootfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_rootfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig conf/buildroot_rootfs_config

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_srcdir)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
	echo $(ISA)
	echo $(filter rv32%,$(ISA))
ifeq (,$(filter rv%c,$(ISA)))
	sed 's/^.*CONFIG_RISCV_ISA_C.*$$/CONFIG_RISCV_ISA_C=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif
ifeq ($(ISA),$(filter rv32%,$(ISA)))
	sed 's/^.*CONFIG_ARCH_RV32I.*$$/CONFIG_ARCH_RV32I=y/' -i $@
	sed 's/^.*CONFIG_ARCH_RV64I.*$$/CONFIG_ARCH_RV64I=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif

$(vmlinux): $(linux_srcdir) $(linux_wrkdir)/.config $(buildroot_initramfs_sysroot_stamp)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- \
		CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(buildroot_initramfs_sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		vmlinux

$(vmlinux_stripped): $(vmlinux)
	$(target)-strip -o $@ $<

.PHONY : uboot_cclass
uboot_cclass:$(uboot_dir) 
		$(MAKE) -C $< O=$(uboot_wrkdir) \
       			CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- \
 			ARCH=riscv \
			$(uboot_config)		
		$(MAKE) -C $< O=$(uboot_wrkdir) \
			 CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- \
 			 ARCH=riscv \
			 -j4

.PHONY: linux-menuconfig
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv savedefconfig
	cp $(dir $<)/defconfig bsp/conf/linux_defconfig

$(bbl): $(pk_srcdir) $(vmlinux_stripped)
	rm -rf $(pk_wrkdir)
	mkdir -p $(pk_wrkdir)
	cd $(pk_srcdir) && ./build.sh ./build $(vmlinux_stripped)
	cp -R $(pk_srcdir)/build $(pk_wrkdir)

$(bin): $(pk_wrkdir)/build/bbl
	$(target)-objcopy -S -O binary --change-addresses -0x80000000 $< $@

#$(hex):	$(bin)
#	xxd -c1 -p $< > $@


	
$(rootfs): $(buildroot_rootfs_ext)
	cp $< $@

.PHONY:bbl_minimal
bbl_minimal: $(linux_srcdir) $(linux_wrkdir)/.config 
		$(MAKE) -C $< O=$(linux_wrkdir) \	
		CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- \
                CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.cpio.gz" \
                CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
                CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
                ARCH=riscv \
                vmlinux

(bbl): $(pk_srcdir) $(vmlinux_stripped)
	rm -rf $(pk_wrkdir)
	mkdir -p $(pk_wrkdir)
	cd $(pk_srcdir) && ./build.sh ./build $(vmlinux_stripped)
	cp -R $(pk_srcdir)/build $(pk_wrkdir)

.PHONY: opensbi
opensbi: $(opensbi_dir) $(buildroot_initramfs_tar)  $(buildroot_initramfs_sysroot_stamp)  $(linux_wrkdir)/.config $(buildroot_initramfs_sysroot)
	  mkdir -p $(opensbi_dir) 
	  $(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) \
                CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- \
              	CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(buildroot_initramfs_sysroot)" \
                CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
                CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
                ARCH=riscv
	  dtc -I dts -O dtb -o $(confdir)/../dts/shakti_100t.dtb $(confdir)/../dts/shakti_100t.dts
	  $(MAKE) -C $< O=$(opensbi_wrkdir) \
		   CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-elf- \
		  PLATFORM=generic	\
		  FW_PAYLOAD_PATH=$(linux_wrkdir)/arch/riscv/boot/Image \
		  FW_FDT_PATH=$(confdir)/../dts/shakti_100t.dtb

.PHONY: image	
image: $(vmlinux_stripped)
	rm -rf output
	mkdir output
	$(RISCV)/bin/riscv64-unknown-elf-objcopy -O binary work/linux/vmlinux output/vmlinux.bin
	mkimage -A riscv -O linux -T kernel -C none -a 0x84000000 -e 0x84000000 -n Shakti-Vajra -d output/vmlinux.bin output/uImage
	cp work/buildroot_initramfs/images/rootfs.tar output/rootfs.tar
	dtc -I dts -O dtb -o output/shakti_100t.dtb $(confdir)/../dts/shakti_100t.dts
	rm -rf output/vmlinux.bin
	cp bsp/conf/shakti_uboot_defconfig bootloaders/uboot/configs/
	$(MAKE) -C $(uboot_dir) $(uboot_config)
	$(MAKE) -C $(uboot_dir) \
		CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- \
		ARCH=riscv \
		-j8
	echo "U-Boot Compiled"
	$(MAKE) -C $(opensbi_dir) \
		CROSS_COMPILE=$(RISCV)/bin/riscv64-unknown-linux-gnu- \
		ARCH=riscv \
		PLATFORM=generic \
		FW_PAYLOAD_PATH=$(wrkdir)/../bootloaders/uboot/u-boot.bin \
		FW_FDT_PATH=$(wrkdir)/../output/shakti_100t.dtb
	cp $(wrkdir)/../bootloaders/shakti-opensbi/build/platform/generic/firmware/fw_payload.elf output/
	cp $(wrkdir)/../bootloaders/shakti-opensbi/build/platform/generic/firmware/fw_payload.bin output/	
	echo "OpenSBI Compilation Done"
	echo "Images Generated and Present at Output Directory..."


.PHONY: buildroot_initramfs_sysroot vmlinux bbl 
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux)
bbl: $(bbl)

.PHONY: clean
clean:
	rm -rf -- $(wrkdir) 
	rm -rf -- bootloaders/riscv-pk/build
	rm -rf -- output

