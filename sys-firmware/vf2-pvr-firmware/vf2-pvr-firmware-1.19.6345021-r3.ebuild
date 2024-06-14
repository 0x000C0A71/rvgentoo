# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Firmware for the IMG_GPU provided by starfive"
HOMEPAGE=""
SRC_URI="
	https://github.com/starfive-tech/soft_3rdpart/raw/JH7110_VisionFive2_devel/IMG_GPU/out/img-gpu-powervr-bin-${PV}.tar.gz
"

S="${WORKDIR}/img-gpu-powervr-bin-${PV}"

LICENSE=""
SLOT="0"
KEYWORDS="~riscv"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""


src_install() {
	insinto /lib/firmware/

	doins target/lib/firmware/rgx.fw.36.50.54.182
	doins target/lib/firmware/rgx.sh.36.50.54.182

	insinto /etc/dracut.conf.d
	doins ${FILESDIR}/dracut-pvr-fw-r1.conf
}

