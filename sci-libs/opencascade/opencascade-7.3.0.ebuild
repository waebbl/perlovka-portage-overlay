# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit check-reqs cmake-utils eapi7-ver java-pkg-opt-2 multilib

MY_PV="$(ver_rs 1- '_')"

DESCRIPTION="Development platform for CAD/CAE, 3D surface/solid modeling and data exchange"
HOMEPAGE="http://www.opencascade.com/"
SRC_URI="https://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=refs/tags/V${MY_PV};sf=tgz -> ${P}.tar.gz"

LICENSE="|| ( Open-CASCADE-LGPL-2.1-Exception-1.0 LGPL-2.1 )"
SLOT="${PV}"
KEYWORDS="~amd64 ~x86"

IUSE="debug doc examples ffmpeg freeimage gl2ps gles2 java +tbb +vtk"

RDEPEND="app-eselect/eselect-opencascade
	ffmpeg? ( virtual/ffmpeg )
	freeimage? ( media-libs/freeimage )
	gl2ps? ( x11-libs/gl2ps )
	java? ( >=virtual/jdk-0:= )
	tbb? ( dev-cpp/tbb )
	vtk? ( sci-libs/vtk[rendering] )
	dev-lang/tcl:0=
	dev-lang/tk:0=
	dev-tcltk/itcl
	dev-tcltk/itk
	dev-tcltk/tix
	media-libs/freetype:2
	media-libs/ftgl
	virtual/glu
	virtual/opengl
	x11-libs/libXmu
"

DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
"

CHECKREQS_MEMORY="256M"
CHECKREQS_DISK_BUILD="3584M"

CMAKE_BUILD_TYPE=Release

S="${WORKDIR}/occt-V${MY_PV}"

PATCHES=(
	"${FILESDIR}/${P}-vtk-compat.patch"
	"${FILESDIR}/${P}-fixed-DESTDIR.patch"
)

pkg_setup() {
	check-reqs_pkg_setup
	use java && java-pkg-opt-2_pkg_setup
}

src_prepare() {
	cmake-utils_src_prepare
	use java && java-pkg-opt-2_src_prepare

	# Do not pre-strip files
	sed -i 's/_FLAGS_RELEASE} -s/_FLAGS_RELEASE}/g' adm/cmake/occt_defs_flags.cmake || die

	# Prepare environment variables used by Opencascade
	local my_install_dir="${EROOT}usr/$(get_libdir)/${P}"

	echo "CASROOT=$my_install_dir
PATH=$my_install_dir/bin
LDPATH=$my_install_dir/lib

CSF_EXCEPTION_PROMPT=1
CSF_GraphicShr=$my_install_dir/lib/libTKOpenGl.so
CSF_IGESDefaults=$my_install_dir/share/opencascade/resources/XSTEPResource
CSF_LANGUAGE=us
CSF_MDTVTexturesDirectory=$my_install_dir/share/opencascade/resources/Textures
CSF_MIGRATION_TYPES=$my_install_dir/share/opencascade/resources/StdResource/MigrationSheet.txt
CSF_PluginDefaults=$my_install_dir/share/opencascade/resources/StdResource
CSF_ShadersDirectory=$my_install_dir/share/opencascade/resources/Shaders
CSF_SHMessage=$my_install_dir/share/opencascade/resources/SHMessage
CSF_StandardDefaults=$my_install_dir/share/opencascade/resources/StdResource
CSF_StandardLiteDefaults=$my_install_dir/share/opencascade/resources/StdResource
CSF_STEPDefaults=$my_install_dir/share/opencascade/resources/XSTEPResource
CSF_UnitsDefinition=$my_install_dir/share/opencascade/resources/UnitsAPI/Units.dat
CSF_XCAFDefaults=$my_install_dir/share/opencascade/resources/StdResource
CSF_XmlOcafResource=$my_install_dir/share/opencascade/resources/XmlOcafResource
CSF_XSMessage=$my_install_dir/share/opencascade/resources/XSMessage

MMGT_CLEAR=1
MMGT_OPT=2
# The next MMGT_* variables are at their default values.
# They are here for documentation, so you can change them if needed
# use TBB for memory allocation optimizations
#MMGT_MMAP=1
#MMGT_CELLSIZE=200
#MMGT_NBPAGES=10000
#MMGT_THRESHOLD=40000
" > "${S}/${PV}"

}

src_configure() {
	local mycmakeargs=(
		-DBUILD_DOC_Overview=$(usex doc)
		-DBUILD_WITH_DEBUG=$(usex debug)
		-DCMAKE_INSTALL_PREFIX="/usr/$(get_libdir)/${P}"
		-DINSTALL_DIR_CMAKE="/usr/$(get_libdir)/cmake"
		-DINSTALL_DIR_DOC="/usr/share/doc/${P}"
		-DINSTALL_SAMPLES=$(usex examples)
		-DUSE_FFMPEG=$(usex ffmpeg)
		-DUSE_FREEIMAGE=$(usex freeimage)
		-DUSE_GL2PS=$(usex gl2ps)
		-DUSE_GLES2=$(usex gles2)
		-DUSE_TBB=$(usex tbb)
		-DUSE_VTK=$(usex vtk)
	)

	cmake-utils_src_configure
}

src_install() {
	cmake-utils_src_install

	local my_libdir="$(get_libdir)"

	chmod go-w "${ED%/}/usr/$my_libdir/${P}/bin/draw.sh" || die

	if ! use examples; then
		rm -rf "${ED%/}/usr/$my_libdir/${P}/share/${PN}/samples" || die
	fi

	insinto "/etc/env.d/${PN}"
	doins "${S}/${PV}"

}

pkg_postinst() {
	eselect ${PN} set ${PV}
	elog "You can switch between available ${PN} implementations using eselect ${PN}."
	elog "After upgrading OpenCASCADE you may have to rebuild packages depending on it."
	elog "You get a list by running \"equery depends sci-libs/opencascade\""
	elog "revdep-rebuild does NOT suffice."
}
