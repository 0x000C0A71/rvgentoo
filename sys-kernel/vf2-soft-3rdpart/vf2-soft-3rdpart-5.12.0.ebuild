# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MODULES_INITRAMFS_IUSE="+initramfs"

inherit linux-mod-r1 udev

VF2_TAG="JH7110_VF2_6.6_v${PV}"

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="
	https://github.com/starfive-tech/soft_3rdpart/archive/refs/tags/${VF2_TAG}.tar.gz -> soft_3rdpart-${VF2_TAG}.tar.gz
"

S="${WORKDIR}/soft_3rdpart-${VF2_TAG}"

LICENSE=""
SLOT="0"
KEYWORDS="~riscv"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

PATCHES=(
	"${FILESDIR}/soft_3rdpart-00-correct_kernel_source_dir.patch"
	"${FILESDIR}/soft_3rdpart-01-use_clang_for_llvm.patch"
)

SRC_JPU="${S}/codaj12/jdi/linux/driver"
SRC_VENC="${S}/wave420l/code/vdi/linux/driver"
SRC_VDEC="${S}/wave511/code/vdi/linux/driver"

src_compile() {
	local modlist=(
		jpu=extra:${SRC_JPU}:${SRC_JPU}
		venc=extra:${SRC_VENC}:${SRC_VENC}
		vdec=extra:${SRC_VDEC}:${SRC_VDEC}
	)
	local modargs=(
		KERNELDIR="${KERNEL_DIR}"
	)

	linux-mod-r1_src_compile
}


src_install() {
	linux-mod-r1_src_install

	einfo "Installing firmware"
	
	cd "${S}"
	insopts -m644

	insinto /lib/firmware

	doins wave420l/firmware/monet.bin
	doins wave420l/code/cfg/encoder_defconfig.cfg
	doins wave511/firmware/chagall.bin



	einfo "Installing HiFi4"

	insinto /lib/firmware/sof

	doins HiFi4/sof-vf2.ri                
	doins HiFi4/sof-vf2-wm8960-aec.tplg   
	doins HiFi4/sof-vf2-wm8960-mixer.tplg 
	doins HiFi4/sof-vf2-wm8960.tplg       


	einfo "Installing config files"

	insinto /lib/modprobe.d
	doins "${FILESDIR}/soft_3rdpart-modules.conf"

	udev_dorules "${FILESDIR}/91-soft_3rdpart.rules"
}

pkg_postinst() {
	linux-mod-r1_pkg_postinst
	udev_reload


	ewarn
	ewarn "The new modules must most likely be integrated into"
	ewarn "the initramfs. If you have installed"
	ewarn "\`sys-kernel/cwt-linux\`, this can be done via"
	ewarn
	ewarn "	emerge --config sys-kernel/cwt-linux"
}
