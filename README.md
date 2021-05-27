Linux Development Kit for Shakti SOC'S
---
The Development kit acts a "One Stop" means to build and deploy linux on a specfic Shakti capable SOC.

To Learn more  about the Shakti and its avaliable SOC , details can be found here at (http://shakti.org.in/)

Salient Features
---
1.  Boots Linux following Version 5.5(Stable)
2.  Makes use of the following Supported Bootloaders such as
     - Proxy Kernel(BBL) -> Supported
     - OpenSBI -> Supported 
     - U-Boot -> Work In Progress
3.  Builds a standalone filesystem which can be loaded on to a compatible block device such as SDCard(Work in Progress)

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
run the following commands,	

    cd riscv-gnu-toolchain
    ./configure --prefix=/opt/riscv --with-arch=rv64imac --with-abi=lp64 --with-cmodel=medany
    sudo make && sudo make linux

Once the above steps are completed you can find the cross-compile and baremetal binaries in the respective path '/opt/riscv/bin' also assuming you have added it to the PATH variable you can proceed to build linux.

Getting started on linux Devlopment
--
The linux development repository uses submodules. You need the --recursive option to fetch the submodules automatically
            
     $ git clone --recursive https://gitlab.com/shaktiproject/software/linux-devkit.git
            
The development package Supports C-Class 64bit Core,which boots linux on top of Proxy Kernel.


Rapid deployment using BBL as a bootloader
--
Linux can be built as a payload to BBL by doing the below command.   

For instance Shakti C-Class is based on RV64IMAC. So alter the config file.

    Location : <Your linux-devkit dir>/buildroot/package/busybox/busybox.config

    CONFIG_EXTRA_CFLAGS="-g -march=rv64imac -mabi=lp64"
    CONFIG_EXTRA_LDFLAGS="-g -march=rv64imac -mabi=lp64"

Also once the above is done, please rebuild it.

	cd linux-devkit

To enable SD Card support follow the below 2 steps :

Add the following line at the end in the fstab file present at buildroot/package/skeleton-init-sysv/skeleton/etc

	devtmpfs	/dev		devtmpfs mode=1777,nouid	0	0

The above line is to make the devtmpfs auto-mount to /dev during bootup. This can be avoid if you can mount the file-system in the terminal using

	mount -t devtmpfs devtmpfs /dev

To start the compilation use the following command 

	make bbl


Devlopment Cycle
-----

The Linux Development Kit has the  following Directories 

* BSP(Board Support Packages) -> Used to store all device trees with configuration specific to a SoC.
* Bootloaders -> Avaliable Bootloaders which can be bundled with a payload and deployed on a Specific SoC.
* Linux-on-Shakti(Submodule Type) -> Linux kernel  Repo forked from offical kernel release :https://github.com/torvalds/linux. Currently on v5.5.
* Buildroot(Submodule Type) -> Used to Combine the above 3 as a deployable along with filesystem and its utilities.

To develop with this kit the following points below must be adhered to.

* If anychange regarding non-submodules or a update is being pushed do create a branch and subsequent merge requests will be processed and approved.
* For Updates regarding Linux Kernel and Buildroot please pull appropriate branches below the submodules to make use of them , to above point 1 update if necessary.

Using SOC to Boot Linux 
-----
Currently the linux kernel boots on ARTY A7 100t with C-Class.

Assuming you have programmed the board and ready to deploy the bbl follow the below steps.

Open Three terminals,
1. Miniterm	
2. OpenOcd
3. RISC-V GDB

* Connect to the board using openocd with shakti-sdk

     $ cd ~/shakti-sdk/bsp/third_party/vajra <br />
     $ sudo $(which openocd) -f ftdi.cfg <br />
     
* Connect to gtkterm or minicom or miniterm with a baudrate of 19200 and port as /dev/ttyUSB

     $ sudo miniterm.py /dev/ttyUSB1 19200 <br />
    
* Using gdb(riscv64-unknown-elf-gdb) load the bbl , steps are given below.

     ​(gdb) set remotetimeout unlimited <br />
     (gdb) ​target remote localhost:3333 <br />
     (gdb) file path/to/linux-devkit/bootloaders/riscv-pk/build/bbl <br />
     (gdb) load	<br />


* Once done inspect the memory at 0x80000000 to check if the image is loaded properly. 

     (gdb) x/10x 0x80000000

GDB after load,

![loads](https://user-images.githubusercontent.com/31366212/83849409-ff30a880-a72c-11ea-8fe8-365b1a0181bd.png)


* Hit Continue to get the output. Output is displayed in Serial Monitor (Miniterm).

      (gdb) c  

* Login details are 

      Login ID : root
      Password : shakti
    
* One can use "adduser" to add new users .

Linux with minimal filesystem (miniterm)
-----
![file](https://user-images.githubusercontent.com/31366212/83849300-d6a8ae80-a72c-11ea-92e2-11d74d098487.png)

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
    $ cp <linux-dev location>/work/riscv-pk/build/bbl ./  
    $ elf2hex 8 33554432 bbl 2147483648 > code.mem  
    $ ./cclass

The output will be gernerated in a text file "app_log" , make use of tail method to recursively see generated log.

Sample Debug Log 
---
![linux](/uploads/63810269b0afd43ab87609a134e71152/linux.png)


note: If you have already installed toolchain, please use it appropriately.
