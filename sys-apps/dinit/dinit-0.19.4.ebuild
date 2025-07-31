EAPI=8

inherit flag-o-matic linux-info toolchain-funcs

DESCRIPTION="Service manager and init system"
HOMEPAGE="https://github.com/davmac314/dinit"
SRC_URI="https://github.com/davmac314/dinit/releases/download/v${PV}/${P}.tar.xz"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="bash-completion caps dinit-init fish-completion zsh-completion"

RDEPEND="
	bash-completion? ( >=app-shells/bash-completion-2.16.0-r1 )
	caps? ( >=sys-libs/libcap-2.76 )
	dinit-init? (
		!sys-apps/openrc
		!sys-apps/sysvinit
	)
	fish-completion? ( >=app-shells/fish-3.7.1 )
	zsh-completion? ( >=app-shells/zsh-completions-0.35.0 )
	>=sys-libs/cgroup-utils-0.7.2
"
BDEPEND="
	|| (
		>=llvm-core/clang-15.0.7-r3
		>=sys-devel/gcc-11.5.0
	)
"
PDEPEND="
	dinit-init? ( >=sys-apps/dinitrc-0.5.0 )
"

PATCHES=(
	"${FILESDIR}"/restart-interval.patch
)

pkg_setup() {
	local CONFIG_CHECK="~CGROUPS"
	use kernel_linux && linux-info_pkg_setup
}

src_configure() {
	# Required C++ standard
	# See https://github.com/davmac314/dinit/blob/63e1aa8dafb01ea1a6251fd7098435bcb5dda38b/BUILD#L137
	append-cxxflags -std=c++11

	# GCC dual ABI handling
	# See https://github.com/davmac314/dinit/blob/63e1aa8dafb01ea1a6251fd7098435bcb5dda38b/BUILD#L258
	if tc-is-gcc; then
		local m=$(gcc-major-version)

		if (( m < 7 )); then
			append-cxxflags -D_GLIBCXX_USE_CXX11_ABI=0
		else
			append-cxxflags -D_GLIBCXX_USE_CXX11_ABI=1
		fi
	fi

	# Build environment variables
	local conf_env=()

	# Configuration options
	local myconf=(
		--disable-ioprio
		--enable-initgroups
		--enable-oom-adj
		--enable-utmpx
		--sbindir=/usr/bin
		--syscontrolsocket=/run/dinitctl
	)

	# Capabilities support
	if use caps; then
		myconf+=( --enable-capabilities )

		conf_env+=(
			LDFLAGS_EXTRA=-lcap
			TEST_LDFLAGS_EXTRA=-lcap
		)
	else
		myconf+=( --disable-capabilities )
	fi

	# Build the "shutdown" (and "halt" etc.) utilities if dinit is the system init
	if use dinit-init; then
		myconf+=( --enable-cgroups --enable-shutdown )
	else
		myconf+=( --disable-cgroups --disable-shutdown )
	fi

	env "${conf_env[@]}" econf "${myconf[@]}"
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

	# dinit-init symlink
	if use dinit-init; then
		dobin "${FILESDIR}"/dinit-init
		dosym /usr/bin/dinit-init /usr/bin/init
	fi
}
