# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

KERNEL_IUSE_MODULES_SIGN=true

inherit kernel-build

CWT_VER="22"
SDK_VER="5.12.0"

VF2_TAG="JH7110_VF2_6.6_v${SDK_VER}"
KV_LOCALVERSION="-cwt${CWT_VER}-v${SDK_VER}"

DESCRIPTION="Linux 5.15.x (-cwt) for StarFive RISC-V VisionFive 2 Board"
HOMEPAGE="https://github.com/cwt-vf2/linux-cwt-starfive-vf2"
SRC_URI="
	https://github.com/starfive-tech/linux/archive/refs/tags/${VF2_TAG}.tar.gz
"

S="${WORKDIR}/linux-${VF2_TAG}"

IUSE="
	debug
	+initramfs
	+modules-sign
	savedconfig
	secureboot
	+strip
	test
	+dracut
"
REQUIRED_USE="dracut"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~riscv"

DEPEND="
	sys-kernel/installkernel[dracut]
"
RDEPEND="${DEPEND}"
BDEPEND=""

MY_FILES="${FILESDIR}/cwt${CWT_VER}"

PATCHES=(
	"${MY_FILES}/linux-01-riscv-zba_zbb.patch"
	"${MY_FILES}/linux-02-eswin_6600u-llvm.patch"
	"${MY_FILES}/linux-03-eswin_6600u-cast_null_as_unsigned_int.patch"
	"${MY_FILES}/linux-04-fix_broken_gpu-drm-i2c-tda998x.patch"
	"${MY_FILES}/linux-05-fix_img_gpu_secondary_notintermediate_conflict.patch"
	"${MY_FILES}/linux-06-fix_drm_img_rogue_buffer_overflow.patch"
	"${MY_FILES}/linux-07-fix_starfive_v4l2_for_6.6_kernel.patch"

)

src_prepare() {
	einfo "Copying over default config"
	cp "${MY_FILES}/config" "${S}/.config"

	default
	eapply_user
}
