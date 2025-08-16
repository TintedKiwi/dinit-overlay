EAPI=8

inherit meson

DESCRIPTION="Work-in-progress session/login tracker as a logind alternative"
HOMEPAGE="https://github.com/chimera-linux/turnstile"
SRC_URI="https://github.com/chimera-linux/turnstile/archive/refs/tags/v${PV}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="doc"

RDEPEND=">=sys-apps/dinitrc-0.5.0"
DEPEND=">=sys-libs/pam-1.7.1"
BDEPEND="
	doc? ( >=app-text/scdoc-1.11.3 )
	>=dev-build/meson-1.7.2
	|| (
		>=llvm-core/clang-15.0.7-r3
		>=sys-devel/gcc-11.5.0
	)
"

src_prepare() {
	default
	eapply "${FILESDIR}"/use-dinit-log-dir.patch
}

src_configure() {
	local emesonargs=(
		-Ddefault_backend=dinit
		-Ddinit=enabled
		-Dlibrary=disabled
		-Dmanage_rundir=true
		-Drunit=disabled
	)

	if use doc; then
		emesonargs+=( -Dman=true )
	else
		emesonargs+=( -Dman=false )
	fi

	meson_src_configure
}

src_compile() {
	meson_src_compile
}

src_install() {
	meson_src_install
}
