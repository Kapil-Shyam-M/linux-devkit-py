Linux Development Kit for Shakti SOC'S
---
The Development kit acts a "One Stop" means to build and deploy linux on a specfic Shakti capable SOC.

To Learn more  about the Shakti and its avaliable SOC , details can be found here at (http://shakti.org.in/)

Salient Features
---
1.  Boots Linux following Version 5.1(Stable)
2.  Makes use of the following Supported Bootloaders such as
        -Proxy Kernel(BBL)
        -U-Boot
        -OpenSBI
3.  Builds a standalone filesystem which can be loaded on to a compatible block device such as SDCard

Getting Started
---

Setting up the Build Enviroment
----


1.  Get the latest RISCV-Toolchain

This repository uses submodules. You need the --recursive option to fetch the submodules automatically

    $ git clone --recursive https://github.com/riscv/riscv-gnu-toolchain
    
Alternatively :

    $ git clone https://github.com/riscv/riscv-gnu-toolchain
    $ cd riscv-gnu-toolchain
    $ git submodule update --init --recursive

2. Install the necessary packages

Several standard packages are needed to build the toolchain.  On Ubuntu,
executing the following command should suffice:

    $ sudo apt-get install autoconf automake autotools-dev curl libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

3. Install the toolchain by doing 

To build the Newlib cross-compiler, pick an install path.  If you choose,
say, `/opt/riscv`, then add `/opt/riscv/bin` to your `PATH` now.  Then, simply
run the following command:

    ./configure --prefix=/opt/riscv
     sudo make && sudo make linux

Once the above steps are completed you can find the cross-compile and baremetal binaries in the respective path '/opt/riscv/bin' also assuming you have added it to the PATH variable you can proceed to build linux.

Getting started on linux Devlopment
--


The development package Supports C-Class 64bit Core,which boots linux on top of Proxy Kernel.

Rapid deployment using BBL as a bootloader
--
Linux can be built as a payload to BBL by doing the below command.

    make bbl

Using Simulator to Boot linux
-----
    
Verilog artifacts
----
Download the verilog artifacts from [here](https://gitlab.com/shaktiproject/cores/c-class/-/jobs/345774982/artifacts/download)

Convert to hex using elf2hex
---

Follow the instructions in the below link to install riscv-isa-sim. This will give elf2hex binary which we will be using later.

    https://github.com/riscv/riscv-isa-sim/blob/master/README.md

Note: set $RISCV to the install path of toolchain. Example: export RISCV=/opt/riscv

Simulation
---
Extract the verilog-artifacts

    $ unzip verilog-artifacts.zip  

Copy the bbl binary and start the simulation.

    $ cd verilog-artifacts/sim  
    $ cp $SHAKTI_LINUX/work/riscv-pk/bbl ./  
    $ elf2hex 8 33554432 bbl 2147483648 > code.mem  
    $ ./cclass

The output will be gernerated in a text file "app_log" , make use of tail method to recursively see generated log.

Sample Debug Log 
---
![linux](/uploads/1f9318ce1087e9cff86ce890b07bfd9d/linux.png)





