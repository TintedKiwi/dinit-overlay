EAPI=8

inherit git-r3 linux-info

DESCRIPTION="Set of cgroup utilities"
HOMEPAGE="https://gitea.artixlinux.org/artix/artix-cgroups"
EGIT_REPO_URI="https://gitea.artixlinux.org/artix/artix-cgroups.git"
EGIT_COMMIT="${PV}"

LICENSE="ArtixLinux"
SLOT="0"
KEYWORDS="amd64 arm64"
PROPERTIES="-live"

COMMON_DEPEND=">=app-shells/bash-5.2_p37-r3"
RDEPEND="${COMMON_DEPEND}"
BDEPEND="${COMMON_DEPEND}"

PATCHES=(
	"${FILESDIR}"/update-makefile.patch
	"${FILESDIR}"/update-cgroups-conf-file-path.patch
)

pkg_setup() {
	local CONFIG_CHECK="~CGROUPS"
	use kernel_linux && linux-info_pkg_setup
}

src_compile() {
	emake PREFIX=/usr DESTDIR="${D}"
}

src_install() {
	emake PREFIX=/usr DESTDIR="${D}" install
	dodoc LICENSE
}
