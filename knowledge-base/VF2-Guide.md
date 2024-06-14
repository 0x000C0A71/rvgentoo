# Step 1: Find a running host
When installing Gentoo on a desktop, you typically use a LiveUSB. As USB booting is not a thing on the Visionfive 2, we'll use another system. We'll boot into that system, connect a second SD card via an USB to SD card adapter, and install Gentoo on that SD card via the running Host.
As a Host, I recommend a cwt Arch image, but it shouldn't matter.

# Step 2: Partitioning the Card
On the SD Card, we'll need 4 partitions:
1. The U-Boot SPL Image
2. The Visionfive 2's firmware payload
3. Our system's EFI system
4. Our system's root partition

We'll need to use a GPT partition table, and the partitions should look as follows:

|                  | Part num | Part Size | Part type                                           | 
| ---------------- | -------- | --------- | --------------------------------------------------- |
| U-Boot SPL Image | 1        | 2M        | HiFive BBL: `2E54B353-1271-4842-806F-E436D6AF6985`       |
| FW Payload       | 2        | 4M        | HiFive FSBL: `5B193300-FC78-40CD-8002-E86C45580B47`      |
| EFI Part         | 3        | 100M+     | EFI System: `C12A7328-F81F-11D2-BA4B-00A0C93EC93B`       |
| Root Part        | 4        | any       | Linux Filesystem: `0FC63DAF-8483-4772-8E79-3D69D8477DE4` |

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
Next we'll create the file systems on the remaining 2 partitions. The EFI partition must be formated as vfat, the root partition can be whatever. I recommend BTRFS. Consider giving the partitions labels as to make mounting them in the fstab and kernel config easier.

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

# Step 5: Setting up the uEnv
For the SPL to be able to launch our system, we need the `uEnv.txt` config file. This tells U-Boot information on how exactly to load all the necessary parts of linux into ram for linux to be able to boot:

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
fdtfile=starfive/jh7110-visionfive-v2.dtb
# Fix missing bootcmd
bootcmd=run load_distro_uenv;run bootcmd_distro
```

We need to copy this file over to our boot partition with its owner set to `root`, its group set to `root` and a permission number of `644`:

```bash
install -o root -g root -m 644 uEnv.txt /mnt/boot/uEnv.txt
```

# Step 6: Installing the Gentoo system
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


# Step 7: Installing a Kernel
This is mostly left for you to figure out. There are many different out of tree kernels for the VisionFive 2 and Gentoo offers a multitude of ways to install a kernel.
I do somewhat maintain an ebuild on [my overlay](https://github.com/XerneraC/backstash) that pulls Starfive's 5.15.x kernel and applies cwt's patches to it as `sys-kernel/cwt-linux`. It builds and installs kernel sources, the kernel image and the initramfs, so no Genkernel or dracut is necessary. If you do not have a diffrent approach in mind I recommend simply installing that.

# Step 8: Configuring U-Boot, our bootloader
There might be a nice utility to generate a U-Boot config, but I don't care.

U-Boot is configured through a file called `extlinux.conf` located at `/boot/extlinux/extlinux.conf`.
First, create the folder:
```bash
mkdir /boot/extlinux
```
and then write the config file.

## extlinux.conf
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
default Gentoo

menu title U-Boot menu
prompt 0
timeout 50

label Gentoo
	menu label Gentoo Linux
	linux /vmlinuz-5.15.2
	initrd /initramfs-5.15.2.img
	fdtdir /dtbs/5.15.2
	append root="LABEL=ROOTFS" rw console=tty1 console=ttyS0,115200 earlycon rootwait stmmaceth=chain_mode:1 selinux=0 rootflags=defaults
```

Refer to [the syslinux wiki page](https://wiki.gentoo.org/wiki/Syslinux#Configuration) for more information (Note that you can be civilized, and the all-caps as shown on the wiki is not necessary)

# Step 9: Follow amd64 handbook
This is pretty much all of the VisionFive 2 specific stuff. To finish up our installation, follow ['Configuring the system'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System "Handbook:AMD64/Installation/System"), ['Installing system tools'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools "Handbook:AMD64/Installation/Tools") & ['Finalizing the installation'](https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing "Handbook:AMD64/Installation/Finalizing") from the amd64 handbook.


# Troubleshooting
## OpenRC Serial Console (i.e. 'Hung on `starting locale`')
By default, OpenRC does not spawn a serial console once booted up. When observing the startup process over a serial console, you'll see it start up as normal, but seem to get stuck once reaching `starting locale`. It is not actually hung. It has sucessfully started, but is not configured to launch a terminal session on the serial console.

### How to enable an aggety serial console
- Write an agetty config file similar to:
```bash
# /etc/conf.d/agetty.ttyS0

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

