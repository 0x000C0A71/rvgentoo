# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit git-r3

DESCRIPTION=""
HOMEPAGE=""
EGIT_REPO_URI="https://gitlab.collabora.com/chipsnmedia/linux-firmware.git"

LICENSE=""
SLOT="0"
KEYWORDS="~riscv"

DEPEND=""
RDEPEND="${DEPEND}"
BDEPEND=""

src_configure() {
	einfo "This package has no configure step"
}

src_compile() {
	einfo "This package has no compile step"
}

src_install() {
	insinto /lib/firmware
	doins cnm/wave511_dec_fw.bin

	insinto /etc/dracut.conf.d
	doins ${FILESDIR}/dracut-vf2-wave5-fw.conf
}
