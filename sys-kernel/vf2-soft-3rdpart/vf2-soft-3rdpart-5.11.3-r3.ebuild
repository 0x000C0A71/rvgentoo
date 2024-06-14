# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod

VF2_TAG="JH7110_VF2_515_v${PV}"

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="
	https://github.com/starfive-tech/soft_3rdpart/archive/refs/tags/${VF2_TAG}.tar.gz -> soft_3rdpart-${VF2_TAG}.tar.gz
"

S="${WORKDIR}/soft_3rdpart-${VF2_TAG}"

IUSE="dist-kernel +modules-sign"
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

MODULE_NAMES="
	jpu(extra:${SRC_JPU}:${SRC_JPU})
	venc(extra:${SRC_VENC}:${SRC_VENC})
	vdec(extra:${SRC_VDEC}:${SRC_VDEC})
"

BUILD_TARGETS="clean default"
BUILD_PARAMS="KERNELDIR='${KERNEL_DIR}'"


src_install() {
	linux-mod_src_install

	if use modules-sign; then
		elog "Signing modules..."

		sign_script="${KERNEL_DIR}/scripts/sign-file"
		key_pem="${KERNEL_DIR}/certs/signing_key.pem"
		key_x509="${KERNEL_DIR}/certs/signing_key.x509"

		[[ -f "${sign_script}" ]] || die "sign script does not exist"
		[[ -f "${key_pem}"     ]] || die "pem key does not exist"
		[[ -f "${key_x509}"    ]] || die "x509 key does not exist"

		ins_dir="${INSTALL_MOD_PATH}/lib/modules/${KV_FULL}/extra"

		einfo "Signing JPU"
		$sign_script sha1 $key_pem $key_x509 "${ins_dir}/jpu.ko" \
			|| die "Failed to sign JPU"

		einfo "Signing VENC"
		$sign_script sha1 $key_pem $key_x509 "${ins_dir}/venc.ko" \
			|| die "Failed to sign VENC"

		einfo "Signing VDEC"
		$sign_script sha1 $key_pem $key_x509 "${ins_dir}/jpu.ko" \
			|| die "Failed to sign JPU"

	fi


	elog "Installing firmware"

	insopts -Dm644

	insinto "${D}/lib/firmware"
	doins "${S}/wave420l/firmware/monet.bin"
	doins "${S}/wave420l/code/cfg/encoder_defconfig.cfg"
	doins "${S}/wave511/firmware/chagall.bin"
	doins "${S}/wave420l/code/cfg/encoder_defconfig.cfg"
	doins "${S}/wave420l/code/cfg/encoder_defconfig.cfg"
	doins "${S}/wave420l/code/cfg/encoder_defconfig.cfg"

	elog "Installing HiFi4"

	insinto "${D}/lib/firmware/sof"
	doins "${S}/HiFi4/sof-vf2.ri"
	doins "${S}/HiFi4/sof-vf2-wm8960-aec.tplg"
	doins "${S}/HiFi4/sof-vf2-wm8960-mixer.tplg"
	doins "${S}/HiFi4/sof-vf2-wm8960.tplg"

	elog "Installing config files"

	insinto "${D}/etc/modprobe.d"
	doins "${FILESDIR}/soft_3rdpart-modules.conf"

	insinto "${D}/usr/share/libalpm/hooks"
	doins "${FILESDIR}/91-soft_3rdpart.hook"

	insinto "${D}/etc/udev/rules.d"
	doins "${FILESDIR}/91-soft_3rdpart.rules"

}
