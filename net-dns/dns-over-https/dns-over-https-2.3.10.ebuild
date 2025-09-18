EAPI=8

inherit flag-o-matic go-module systemd

DESCRIPTION="Client and server software to query DNS over HTTPS, using Google DNS-over-HTTPS protocol"
HOMEPAGE="https://github.com/m13253/dns-over-https"
SRC_URI="https://github.com/m13253/dns-over-https/archive/v${PV}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="amd64 arm64"
IUSE="+client dinit +server test"
REQUIRED_USE="
	|| ( client server )
"

# Restrict network-sandbox to download Go modules until vendor files can be hosted or provided by upstream
RESTRICT="
	!test? ( test )
	network-sandbox
"

S="${WORKDIR}/${PN}-${PV}"

RDEPEND="
	dinit? ( >=sys-apps/dinit-0.19.4 )
"
BDEPEND="
	>=dev-lang/go-1.24.6
"

src_prepare() {
	default

	filter-flags -flto
	filter-ldflags -flto

	sed -i 's/\/local//g' systemd/doh-{client,server}.service

	if use dinit; then
		eapply "${FILESDIR}"/dinit/nm-dispatcher-use-dinitctl.patch
	fi
}

src_compile() {
	export GOFLAGS="${GOFLAGS} -trimpath"

	export CGO_CFLAGS="${CFLAGS}"
	export CGO_CPPFLAGS="${CPPFLAGS}"
	export CGO_LDFLAGS="${LDFLAGS}"

	if use client; then
		ego build -v -o client ./doh-client
	fi

	if use server; then
		ego build -v -o server ./doh-server
	fi
}

src_install() {
	dodoc Readme.md

	if use client; then
		newbin client doh-client

		insinto /etc/dns-over-https
		doins doh-client/doh-client.conf

		exeinto /etc/NetworkManager/dispatcher.d
		doexe NetworkManager/dispatcher.d/doh-client

		if use dinit; then
			insinto /etc/dinit.d
			doins "${FILESDIR}"/dinit/doh-client
		fi

		newinitd "${FILESDIR}"/doh-client.initd doh-client

		systemd_dounit systemd/doh-client.service
	fi

	if use server; then
		newbin server doh-server

		insinto /etc/dns-over-https
		doins doh-server/doh-server.conf

		exeinto /etc/NetworkManager/dispatcher.d
		doexe NetworkManager/dispatcher.d/doh-server

		if use dinit; then
			insinto /etc/dinit.d
			doins "${FILESDIR}"/dinit/doh-server
		fi

		newinitd "${FILESDIR}"/doh-server.initd doh-server

		systemd_dounit systemd/doh-server.service
	fi
}

src_test() {
	go test -v ./... || die "Tests failed"
}
