# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit meson systemd

DESCRIPTION="Minimal seat management daemon and universal library"
HOMEPAGE="https://sr.ht/~kennylevinsen/seatd"
if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.sr.ht/~kennylevinsen/seatd"
else
	KEYWORDS="~alpha amd64 arm arm64 ~loong ~ppc ppc64 ~riscv ~sparc x86"
	SRC_URI="https://git.sr.ht/~kennylevinsen/seatd/archive/${PV}.tar.gz -> ${P}.tar.gz"
fi
LICENSE="MIT"
SLOT="0/1"
IUSE="+builtin +dinit-init elogind openrc +server systemd"
REQUIRED_USE="?? ( elogind systemd )"

DEPEND="
	elogind? ( sys-auth/elogind )
	systemd? ( sys-apps/systemd:= )
"
RDEPEND="${DEPEND}
	dinit-init? ( >=sys-apps/dinitrc-0.5.0 )
	openrc? ( sys-apps/openrc )
	server? ( acct-group/seat )
"
BDEPEND=">=app-text/scdoc-1.9.7"

src_configure() {
	local emesonargs=(
		-Dman-pages=enabled
		$(meson_feature builtin libseat-builtin)
		$(meson_feature server)
	)

	if use elogind ; then
		emesonargs+=( -Dlibseat-logind=elogind )
	elif use systemd; then
		emesonargs+=( -Dlibseat-logind=systemd )
	else
		emesonargs+=( -Dlibseat-logind=disabled )
	fi

	meson_src_configure
}

src_install() {
	meson_src_install

	if use server; then
		if use openrc; then
			newinitd "${FILESDIR}/seatd.initd-r1" seatd
		elif use dinit-init; then
			insinto /etc/dinit.d
			doins "${FILESDIR}"/dinit/seatd
		elif use systemd; then
			systemd_dounit contrib/systemd/seatd.service
		fi

		if has_version '<sys-auth/seatd-0.7.0-r2'; then
			elog "For OpenRC users: seatd is now using the 'seat' group instead of the 'video' group"
			elog "Make sure your user(s) are in the 'seat' group."
			elog "Note: 'video' is still needed for GPU access like OpenGL"
		fi
	fi
}
