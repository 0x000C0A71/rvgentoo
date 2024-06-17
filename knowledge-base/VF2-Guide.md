# Disclaimer
I am not an expert on anything touched upon by this document. Most of what is in here I've figured out by trial and error and/or by reading [cwt's arch image script](https://github.com/cwt-vf2/archlinux-image-vf2) and there is a good chance that I have made several mistakes. I am running a system on my Visionfive 2 that is built exactly like described in this document and it's running without any issues, but If you see something in here that is wrong and/or could use improvement please notify me.

# Step 1: Find a running host
When installing Gentoo on a desktop, you typically use a LiveUSB. As USB booting is not a thing on the Visionfive 2, we'll use another system. We'll boot into that system, connect a second SD card via an USB to SD card adapter, and install Gentoo on that SD card via the running Host.
As a Host, I recommend a cwt Arch image, but it shouldn't matter.

# Step 2: Partitioning the Card
On the SD Card, we'll need 4 partitions:
1. The U-Boot SPL Image
2. The Visionfive 2's firmware payload
3. Our system's EFI system
4. Our system's root partition

We'll need to use a GPT partition table, and the partitions should look something like the following:

|                  | Part num | Part Size | Part type                                           | 
| ---------------- | -------- | --------- | --------------------------------------------------- |
| U-Boot SPL Image | 1        | 2M        | HiFive BBL: `2E54B353-1271-4842-806F-E436D6AF6985`       |
| FW Payload       | 2        | 4M        | HiFive FSBL: `5B193300-FC78-40CD-8002-E86C45580B47`      |
| EFI Part         | 3        | 100M+     | EFI System: `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`       |
| Root Part        | 4        | any       | Linux Filesystem: `0FC63DAF-8483-4772-8E79-3D69D8477DE4` |

As were storing all our kernels and initramfses on the EFI partition, it might be a good idea to make that a bit bigger than 100M if you plan on having multiple kernel versions on it at the same time.

# Step 3: Flashing SPL and FW
Next we'll flash the U-Boot SPL Image and the Firmware payload to the first 2 partitions. Both image files can be downloaded from [Starfive's VisionFive2 SDK Repo](https://github.com/starfive-tech/VisionFive2) under the [Releases section](https://github.com/starfive-tech/VisionFive2/releases).

We need `u-boot-spl.bin.normal.out` (U-Boot SPL Image) and `visionfive2_fw_payload.img` (FW Payload).
Simply `wget` or `curl` them into your working directory.

From there, we flash them to the SD Card:
```bash
dd if=u-boot-spl.bin.normal.out of={spl partition} bs=512
dd if=visionfive2_fw_payload.img of={fw payload partition} bs=512
```

# Step 4: Creating and mounting the Root FS & EFI FS
Next we'll create the file systems on the remaining 2 partitions. The EFI partition must be formatted as vfat, the root partition can be whatever. I recommend BTRFS. Consider giving the partitions labels as to make mounting them in the fstab and kernel config easier.

```bash
mkfs.vfat  -n EFI {efi partition}
mkfs.btrfs -L ROOTFS {root partition}
```

Now we mount both. The root partition can be mounted wherever, the EFI partition must be mounted inside the root partition to a folder `/boot`. This folder must be created:

```bash
mount {root partition} /mnt
mkdir /mnt/boot
mount {efi partition} /mnt/boot
```

# Step 5: Installing the Gentoo system
Follow the sections ['Installing the Gentoo installation files'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage) & ['Installing the Gentoo base system'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base) from the amd64 handbook with the following differences:

## CFLAGS and CXXFLAGS
On riscv, `-march=native` is not a thing. Therefore, `-march=`, `-mcpu=` and `-mtune=` must be explicitly specified.

For the VisionFive 2 they are:
- `-march=rv64imafdc_zicsr_zba_zbb`
- `-mcpu=sifive-u74`
- `-mtune=sifive-7-series`

## Preparing for a bootloader
Already done

## CPU\_FLAGS\_*
No such `USE_EXPAND` exists for riscv. Can be skipped.


# Step 6: Installing a Kernel & other VF2 specific packages

## Kernel
This is mostly left for you to figure out. There are many different out of tree kernels for the VisionFive 2 and Gentoo offers a multitude of ways to install a kernel.
I do somewhat maintain an ebuild port of the cwt kernels on [my overlay](https://github.com/0x000C0A71/rvgentoo) that pulls Starfive's kernel and applies cwt's patches to it as `sys-kernel/cwt-linux`. It builds and installs kernel sources, the kernel image and the initramfs, so no Genkernel or dracut is necessary. If you do not have a different approach in mind I recommend simply installing that.

## Other VF2 specific packages
There are some things that are still left to get the VF2's hardware running. Namely:
- Firmware (`sys-firmware/visionfive2-firmware` from [my overlay](https://github.com/0x000C0A71/rvgentoo))
- IMG gpu userspace driver (`media-libs/img-gpu` from [my overlay](https://github.com/0x000C0A71/rvgentoo))
- 3rd party kernel modules (`sys-kernel/vf2-soft-3rdpart` from [my overlay](https://github.com/0x000C0A71/rvgentoo), setting the `modules-sign` USE flag is recommended)

After these are installed, it is necessary to rebuild the initramfs. If you've installed the `sys-kernel/cwt-linux` kernel that can be done with

```bash
emerge --config sys-kernel/cwt-linux
```


# Step 7: Configuring U-Boot, our bootloader
There might be a nice utility to generate a U-Boot config, but I don't care.

## Setting up the uEnv
For the SPL to be able to launch our system, we need the `uEnv.txt` config file. This gives U-Boot information on how exactly to load all the necessary parts of linux into ram for linux to be able to boot:

``` title:uEnv.txt
fdt_high=0xffffffffffffffff
initrd_high=0xffffffffffffffff
kernel_addr_r=0x44000000
kernel_comp_addr_r=0x90000000
kernel_comp_size=0x10000000
fdt_addr_r=0x48000000
ramdisk_addr_r=0x48100000
# Move distro to first boot to speed up booting
boot_targets=distro mmc0 dhcp 

# Fix wrong fdtfile name
fdtfile=starfive/jh7110-starfive-visionfive-2-v1.3b.dtb

# Fix missing bootcmd
bootcmd=run load_distro_uenv;run bootcmd_distro
```
The `fdtfile` parameter must reference a device tree blob in your `/boot/dtbs/<kernel_version>/` directory that matches your hardware. Different kernel versions might emit blobs with different names (e.g. version 5.12.0 of the Visionfive 2 software renamed them), and different board revisions might require different blobs (e.g. the blob referenced in the example above is for version 1.3B of the board). Be sure to check what blobs you have and what blob you need to change the `fdtfile` parameter accordingly.

This file needs its owner and group both set to `root` and a permission number of `644`:
```bash
chown root:root /boot/uEnv.txt
chmod 664 /boot/uEnv.txt
```

## The extlinux config
U-Boot is configured through a file called `extlinux.conf` located at `/boot/extlinux/extlinux.conf`.
First, create the folder:
```bash
mkdir /boot/extlinux
```
and then write the config file.

### extlinux.conf
The `extlinux.conf` file is structured as follows:

```
default <default boot option>

menu title U-Boot menu
prompt 0
timeout 50

label <boot option A>
	menu label <boot option name>
	linux <linux image>
	initrd <initramfs image>
	fdtdir <device trees>
	append <kernel parameters>

label <boot option B>
	menu label <boot option name>
	linux <linux image>
	initrd <initramfs image>
	fdtdir <device trees>
	append <kernel parameters>
```

All paths in this file are relative to the root of the EFI partition. The device trees can be found in the `/boot/dtbs/` directory versioned by kernel version. Kernel parameters and what they do are outside the scope of this guide, but important is the `root=` parameter, that tells the kernel what partition contains the root file system. Syntax is identical to that of the fstab.

Similarly to the `uEnv.txt` file, the `extlinux.conf` file must also have its owner set to `root`, its group set to `root` and a permission number of `644`.

My `extlinux.conf`, for example, looks like this:
```
default kver_6_6_20

menu title U-Boot menu
prompt 0
timeout 50

label kver_5_15_2
	menu label Gentoo Linux version 5.15.2
	linux /vmlinuz-5.15.2
	initrd /initramfs-5.15.2.img
	fdtdir /dtbs/5.15.2
	append root="LABEL=VF2" rw console=tty1 console=ttyS0,115200 earlycon rootwait stmmaceth=chain_mode:1 selinux=0 rootflags=defaults

label kver_6_6_20
	menu label Gentoo Linux version 6.6.20
	linux /vmlinuz-6.6.20
	initrd /initramfs-6.6.20.img
	fdtdir /dtbs/6.6.20
	append root="LABEL=VF2" rw console=tty1 console=ttyS0,115200 earlycon rootwait stmmaceth=chain_mode:1 selinux=0 rootflags=defaults
```

Refer to [the syslinux wiki page](https://wiki.gentoo.org/wiki/Syslinux#Configuration) for more information (Note that you can be civilized, and the all-caps as shown on the wiki is not necessary)

# Step 8: Follow amd64 handbook
This is pretty much all of the VisionFive 2 specific stuff. To finish up our installation, follow ['Configuring the system'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System "Handbook:AMD64/Installation/System"), ['Installing system tools'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools "Handbook:AMD64/Installation/Tools") & ['Finalizing the installation'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing "Handbook:AMD64/Installation/Finalizing") from the amd64 handbook.


# Troubleshooting
## OpenRC Serial Console (i.e. 'Hung on `starting locale`')
By default, OpenRC does not spawn a serial console once booted up. When observing the startup process over a serial console, you'll see it start up as normal, but seem to get stuck once reaching `starting locale`. It is not actually hung. It has successfully started, but is not configured to launch a terminal session on the serial console.

### How to enable an agetty serial console
- Write an agetty config file `/etc/conf.d/agetty.ttyS0` similar to:
```bash title:'/etc/conf.d/agetty.ttyS0'
# make agetty quiet
#quiet="yes"

# Set the baut rate of the terminal line
baud="115200"

# set the terminal type
#term_type="linux"

# extra options to pass to agetty for this port
#agetty_options=""
```
- Symlink the agetty initscript as follows:
```bash
ln -s /etc/init.d/agetty /etc/init.d/agetty.ttyS0
```
- Enable the service:
```bash
rc-update add agetty.ttyS0 default
```
