EAPI=8

inherit meson

DESCRIPTION="Work-in-progress session/login tracker as a logind alternative"
HOMEPAGE="https://github.com/chimera-linux/turnstile"
SRC_URI="https://github.com/chimera-linux/turnstile/archive/refs/tags/v${PV}.tar.gz"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="man"

RDEPEND=">=sys-apps/dinitrc-0.6.4"
DEPEND="
	>=sys-auth/pambase-20250223
	>=sys-libs/pam-1.7.1
"
BDEPEND="
	man? ( >=app-text/scdoc-1.11.3 )
	>=dev-build/meson-1.7.2
	|| (
		>=llvm-core/clang-15.0.7-r3
		>=sys-devel/gcc-11.5.0
	)
"

src_configure() {
	local emesonargs=(
		-Ddefault_backend=dinit
		-Ddinit=enabled
		-Dlibrary=disabled
		-Dmanage_rundir=true
		-Drunit=disabled
		$(meson_use man)
	)

	meson_src_configure
}

src_compile() {
	meson_src_compile
}

src_install() {
	meson_src_install

	rm -f "${D}"/etc/dinit.d/turnstiled

	insinto /etc/dinit.d
	doins "${FILESDIR}"/turnstiled
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		ewarn
		ewarn "Please ensure that the PAM module is in"
		ewarn "your login path:"
		ewarn
		ewarn "/etc/pam.d/system-login"
		ewarn "-session optional pam_turnstile.so"
		ewarn

		elog
		elog "By default Turnstile manages the user"
		elog "runtime directory (XDG_RUNTIME_DIR)."
		elog
		elog "This can be disabled in the config file:"
		elog
		elog "/etc/turnstile/turnstiled.conf"
		elog "manage_rundir = no"
		elog

		ewarn
		ewarn "If you disable this, you MUST rebuild elogind with the 'turnstile'"
		ewarn "USE flag disabled to restore rundir management."
		ewarn
	fi
}
