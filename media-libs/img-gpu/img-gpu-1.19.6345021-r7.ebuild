# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION=""
HOMEPAGE=""
SRC_URI="
	https://github.com/starfive-tech/soft_3rdpart/raw/JH7110_VisionFive2_devel/IMG_GPU/out/img-gpu-powervr-bin-${PV}.tar.gz
"

# TODO: Add useflag support for opencl vulkan and gles
# TODO: /etc/init.d/rc.pvr is not yet installed
IUSE="
	+testbins
"

S="${WORKDIR}/img-gpu-powervr-bin-${PV}"

LICENSE=""
SLOT="0"
KEYWORDS="~riscv"

DEPEND="
	>=sys-firmware/vf2-pvr-firmware-${PV}
"
RDEPEND="${DEPEND}"
BDEPEND=""

src_install() {
	insinto /usr/lib64
	exeinto /usr/bin

	# libraries
	doins target/usr/lib/libglslcompiler.so.${PV}
	doins target/usr/lib/libpvr_dri_support.so.${PV}
	doins target/usr/lib/libsrv_um.so.${PV}
	doins target/usr/lib/libsutu_display.so.${PV}
	doins target/usr/lib/libGLESv1_CM_PVR_MESA.so.${PV}
	doins target/usr/lib/libPVROCL.so.${PV}
	doins target/usr/lib/libPVRScopeServices.so.${PV}
	doins target/usr/lib/libufwriter.so.${PV}
	doins target/usr/lib/libusc.so.${PV}
	doins target/usr/lib/libVK_IMG.so.${PV}
	doins target/usr/lib/libGLESv2_PVR_MESA.so.${PV}
	#doins target/usr/lib/libvulkan.so.${PV}

	# Symlinks
	doins target/usr/lib/libPVROCL.so
	doins target/usr/lib/libVK_IMG.so
	doins target/usr/lib/libPVRScopeServices.so
	doins target/usr/lib/libsutu_display.so
	doins target/usr/lib/libpvr_dri_support.so
	doins target/usr/lib/libglslcompiler.so
	doins target/usr/lib/libufwriter.so
	doins target/usr/lib/libGLESv1_CM_PVR_MESA.so
	doins target/usr/lib/libGLESv2_PVR_MESA.so
	doins target/usr/lib/libsrv_um.so
	doins target/usr/lib/libPVROCL.so.1
	#doins target/usr/lib/libGLESv1_CM.so.1
	#doins target/usr/lib/libGLESv1_CM.so
	doins target/usr/lib/libVK_IMG.so.1
	doins target/usr/lib/libusc.so

	# executables
	if use testbins; then
		doexe target/usr/local/bin/rgx_triangle_test
		doexe target/usr/local/bin/pvrhtbd
		doexe target/usr/local/bin/rogue2d_unittest
		doexe target/usr/local/bin/pvrsrvctl
		doexe target/usr/local/bin/rgx_compute_test
		doexe target/usr/local/bin/pvr_memory_test
		doexe target/usr/local/bin/ocl_unit_test
		doexe target/usr/local/bin/pvrdebug
		doexe target/usr/local/bin/hwperfbin2jsont
		doexe target/usr/local/bin/pvrhtb2txt
		doexe target/usr/local/bin/pvr_mutex_perf_test_mx
		doexe target/usr/local/bin/rogue2d_fbctest
		doexe target/usr/local/bin/rgx_twiddling_test
		doexe target/usr/local/bin/hwperfjsonmerge.py
		doexe target/usr/local/bin/rgx_blit_test
		doexe target/usr/local/bin/ocl_extended_test
		doexe target/usr/local/bin/pvrtld
		doexe target/usr/local/bin/pvrlogsplit
		doexe target/usr/local/bin/pvrlogdump
		doexe target/usr/local/bin/pvrhwperf
		doexe target/usr/local/bin/tqplayer
	fi

	insinto /etc
	doins -r target/etc/OpenCL/
	
	insinto /usr/share
	doins -r target/etc/vulkan/
}
