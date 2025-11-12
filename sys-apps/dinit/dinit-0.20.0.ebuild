EAPI=8

inherit flag-o-matic linux-info toolchain-funcs

DESCRIPTION="Service manager and init system"
HOMEPAGE="https://github.com/davmac314/dinit"
SRC_URI="https://github.com/davmac314/dinit/releases/download/v${PV}/${P}.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="bash-completion caps fish-completion +init symlink zsh-completion"
REQUIRED_USE="
	symlink? ( init )
"

RDEPEND="
	bash-completion? ( >=app-shells/bash-completion-2.16.0-r1 )
	caps? ( >=sys-libs/libcap-ng-0.8.5 )
	fish-completion? ( >=app-shells/fish-3.7.1 )
	init? (
		!sys-apps/systemd
		>=sys-libs/cgroup-utils-0.7.2
	)
	symlink? (
		!sys-apps/openrc
		!sys-apps/s6
		!sys-apps/s6-linux-init
		!sys-apps/s6-rc
		!sys-apps/sysvinit
		!sys-process/runit
	)
	zsh-completion? ( >=app-shells/zsh-completions-0.35.0 )
"
DEPEND=">=sys-kernel/linux-headers-6.12"
BDEPEND="
	|| (
		>=llvm-core/clang-15.0.7-r3
		>=sys-devel/gcc-11.5.0
	)
	>=sys-devel/m4-1.4.20
"
PDEPEND="
	init? ( >=sys-apps/dinitrc-0.6.4 )
"

PATCHES=(
	"${FILESDIR}"/restart-interval.patch
)

pkg_setup() {
	local CONFIG_CHECK="~CGROUPS ~CONFIG_PROC_FS"
	linux-info_pkg_setup
}

src_configure() {
	# Required C++ standard
	# See https://github.com/davmac314/dinit/blob/c2bdb9e89fe40f74b9d752c2f2b97b06811d8f3b/BUILD#L150
	append-cxxflags -std=c++11

	# Disable RTTI
	# See https://github.com/davmac314/dinit/blob/c2bdb9e89fe40f74b9d752c2f2b97b06811d8f3b/BUILD#L154
	append-cxxflags -fno-rtti

	# Enable better code generation for non-static builds
	# See https://github.com/davmac314/dinit/blob/c2bdb9e89fe40f74b9d752c2f2b97b06811d8f3b/BUILD#L159
	append-cxxflags -fno-plt

	# Configuration options
	local myconf=(
		--enable-cgroups
		--enable-initgroups
		--enable-ioprio
		--enable-oom-adj
		--enable-utmpx
		--sbindir=/usr/bin
		--syscontrolsocket=/run/dinitctl
	)

	if use caps; then
		myconf+=( --enable-capabilities )
	else
		myconf+=( --disable-capabilities )
	fi

	# Build the 'shutdown' (and 'halt' etc.) utilities
	if use init; then
		myconf+=( --enable-shutdown )

		if ! use symlink; then
			myconf+=( '--shutdown-prefix=dinit-' )
		fi
	else
		myconf+=( --disable-shutdown )
	fi

	econf "${myconf[@]}"
}

src_install() {
	emake DESTDIR="${D}" install

	# shell completions
	if use bash-completion; then
		insinto /usr/share/bash-completion/completions
		doins contrib/shell-completion/bash/dinitctl
	elif use fish-completion; then
		insinto usr/share/fish/completions
		doins contrib/shell-completion/fish/dinitctl.fish
	elif use zsh-completion; then
		insinto /usr/share/zsh/site-functions
		doins contrib/shell-completion/zsh/_dinit
	fi

	if use init; then
		dobin "${FILESDIR}"/dinit-init

		if use symlink; then
			dosym /usr/bin/dinit-init /usr/bin/init
		fi
	fi
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		if use init && ! use symlink; then
			elog
			elog "Dinit can be used as the system init by setting"
			elog "'init=/sbin/dinit-init' on the kernel command-line."
			elog
			elog "Dinit can be used exclusively as system init by"
			elog "setting the 'symlink' USE flag on this package."
			elog

			ewarn
			ewarn "Setting the 'symlink' USE flag will remove"
			ewarn "all other init packages (OpenRC, Runit etc)."
			ewarn
			ewarn "Dinit uses its own system utilities ('halt', 'shutdown' etc)."
			ewarn "When the 'symlink' USE flag is NOT set, these utilities will"
			ewarn "be prefixed with 'dinit-', for example 'dinit-shutdown'."
			ewarn
		fi
	fi
}
