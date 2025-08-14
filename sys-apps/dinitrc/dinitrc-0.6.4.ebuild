EAPI=8

inherit linux-info tmpfiles

DESCRIPTION="RC files for dinit"
HOMEPAGE="https://gitea.artixlinux.org/artix/dinit-rc"
SRC_URI="https://gitea.artixlinux.org/artix/dinit-rc/archive/${PVR}.tar.gz"

LICENSE="BSD GPL-3+"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="+turnstile"

S="${WORKDIR}/dinit-rc"

COMMON_DEPEND=">=app-shells/bash-5.2_p37-r3"
RDEPEND="${COMMON_DEPEND}
	turnstile? ( >=sys-auth/elogind-255.17 )
	>=net-misc/iputils-20250605-r1
	>=sys-apps/dbus-1.16.2
	>=sys-apps/dinit-0.19.4[init]
	>=sys-apps/iproute2-6.15.0
	>=sys-apps/kmod-33
	>=sys-apps/util-linux-2.41.1
	>=sys-libs/cgroup-utils-0.7.2
	>=sys-process/procps-4.0.5-r2
	virtual/tmpfiles
	virtual/udev
"
BDEPEND="${COMMON_DEPEND}
	>=app-text/scdoc-1.11.3
"
PDEPEND="
	turnstile? (
		>=sys-auth/seatd-0.9.1[builtin,elogind,server]
		>=sys-auth/turnstile-0.1.10
	)
"

PATCHES=(
	"${FILESDIR}"/update-systemd-utils-path.patch
	"${FILESDIR}"/update-cgroup-utils-path.patch
)

pkg_setup() {
	local CONFIG_CHECK="~CGROUPS"
	use kernel_linux && linux-info_pkg_setup
}

src_install() {
	emake DESTDIR="${D}" install

	insinto /etc
	doins "${FILESDIR}"/rc.local
	doins "${FILESDIR}"/rc.shutdown

	if use turnstile; then
		insinto /etc/dinit.d
		doins "${FILESDIR}"/logind

		dodir /etc/dinit.d/boot.d
		dosym /etc/dinit.d/logind /etc/dinit.d/boot.d/logind
	fi

	insinto etc/profile.d
	doins "${FILESDIR}"/locale.sh

	keepdir /var/log/dinit

	# iputils
	keepdir /usr/lib/sysctl.d

	dodoc COPYING
}

pkg_postinst() {
	tmpfiles_process dinit-rc.conf
}
