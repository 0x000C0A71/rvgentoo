# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

IUSE="+pvr-gpu +wifi +bluetooth +wave5"

vf2_tag="JH7110_VF2_515_v${PV}"

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="
	https://github.com/starfive-tech/buildroot/archive/refs/tags/${vf2_tag}.tar.gz -> buildroot-${vf2_tag}.tar.gz
"

S="${WORKDIR}/buildroot-${vf2_tag}"

LICENSE=""
SLOT="0"
KEYWORDS="~riscv"

DEPEND="
	pvr-gpu? ( sys-firmware/vf2-pvr-firmware )
	wave5? ( sys-firmware/vf2-wave5-firmware )
"
RDEPEND="${DEPEND}"
BDEPEND=""

fw_path="package/starfive/starfive-firmware"

src_configure() {
	einfo "This package has no configure step"
}

src_compile() {
	einfo "This package has no compile step"
}

src_install() {

	# wifi firmware
	if use wifi; then
		einfo "installing wifi firmware..."

		insinto /lib/firmware

		doins ${fw_path}/ECR6600U-usb-wifi/ECR6600U_transport.bin
		doins ${fw_path}/ap6256-sdio-wifi/*

		doins -r ${fw_path}/aic8800-usb-wifi/aic8800
		doins -r ${fw_path}/aic8800-usb-wifi/aic8800DC

		einfo "installing wifi configs..."
		insinto /usr/lib/dracut/dracut.conf.d
		doins ${FILESDIR}/dracut-conf-vf2fw-wifi.conf
	fi

	# bluetooth firmware
	if use bluetooth; then
		einfo "installing bluetooth firmware..."

		insinto /lib/firmware

		doins ${fw_path}/ap6256-bluetooth/BCM4345C5.hcd
		doins ${fw_path}/rtl8852bu-bluetooth/*


		einfo "installing bluetooth configs..."
		insinto /usr/lib/dracut/dracut.conf.d
		doins ${FILESDIR}/dracut-conf-vf2fw-bluetooth.conf

		# TODO:
		#   There is an init script
		#   `${fw_path}/ap6256-bluetooth/S36ap6256-bluetooth`
		#   to be installed into `/etc/init.d/`. This is skipped
		#   for now, as I am not 100% sure for what init system
		#   that script is designed
	fi

}


