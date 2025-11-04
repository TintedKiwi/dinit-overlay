# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# Be careful with packaging odd-version-number branches!
# We should at the very least keep stable as an upstream stable branch,
# possibly even ~arch too, given the note about security releases on their website.
# See https://www.freedesktop.org/wiki/Software/dbus/#download.

PYTHON_COMPAT=( python3_{11..14} )
TMPFILES_OPTIONAL=1

inherit linux-info meson-multilib python-any-r1 readme.gentoo-r1 systemd tmpfiles virtualx

DESCRIPTION="A message bus system, a simple way for applications to talk to each other"
HOMEPAGE="https://www.freedesktop.org/wiki/Software/dbus/"
SRC_URI="https://dbus.freedesktop.org/releases/dbus/${P}.tar.xz"

LICENSE="|| ( AFL-2.1 GPL-2+ ) Apache-2.0 BSD GPL-2+ LGPL-2.1+ MIT tcltk"
SLOT="0"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 ~sparc x86 ~amd64-linux ~x86-linux ~ppc-macos ~x64-macos ~x64-solaris"
# TODO: USE=daemon
IUSE="apparmor debug dinit doc elogind selinux static-libs systemd test valgrind X"
RESTRICT="!test? ( test )"

BDEPEND="
	${PYTHON_DEPS}
	app-text/xmlto
	app-text/docbook-xml-dtd:4.4
	acct-user/messagebus
	dev-build/autoconf-archive
	virtual/pkgconfig
	doc? ( app-text/doxygen )
"
COMMON_DEPEND="
	>=dev-libs/expat-2.1.0
	elogind? ( sys-auth/elogind )
	selinux? (
		sys-process/audit
		sys-libs/libselinux
	)
	systemd? ( sys-apps/systemd:= )
	X? (
		x11-libs/libX11
		x11-libs/libXt
	)
"
DEPEND="
	${COMMON_DEPEND}
	test? ( >=dev-libs/glib-2.40:2[${MULTILIB_USEDEP}] )
	valgrind? ( >=dev-debug/valgrind-3.6 )
	X? ( x11-base/xorg-proto )
"
RDEPEND="
	${COMMON_DEPEND}
	acct-user/messagebus
	apparmor? ( >=sys-libs/libapparmor-4.0.3 )
	dinit? (
		>=app-shells/bash-5.2_p37-r3
		>=sys-libs/cgroup-utils-0.7.2
	)
	selinux? ( sec-policy/selinux-dbus )
	systemd? ( virtual/tmpfiles )
"
PDEPEND="
	dinit? ( >=sys-apps/dinitrc-0.6.4 )
"

DOC_CONTENTS="
	Some applications require a session bus in addition to the system
	bus. Please see \`man dbus-launch\` for more information.
"

PATCHES=(
	"${FILESDIR}"/${PN}-1.16.0-enable-elogind.patch # bug #599494
)

pkg_setup() {
	# Python interpeter required unconditionally (bug #932517)
	python-any-r1_pkg_setup

	if use kernel_linux; then
		CONFIG_CHECK="~EPOLL"
		linux-info_pkg_setup
	fi
}

src_prepare() {
	default

	if use dinit; then
		eapply "${FILESDIR}"/dinit/set-message-bus-uid.patch
		eapply "${FILESDIR}"/dinit/0001-add-flag-for-dinit-activated-launch.patch
		eapply "${FILESDIR}"/dinit/0002-add-dinit-environment-updating.patch
	fi
}

src_configure() {
	local rundir=$(usex kernel_linux /run /var/run)

	sed -e "s;@rundir@;${EPREFIX}${rundir};g" "${FILESDIR}"/dbus.initd.in \
		> "${T}"/dbus.initd || die

	meson-multilib_src_configure
}

multilib_src_configure() {
	local emesonargs=(
		--localstatedir="${EPREFIX}/var"
		-Druntime_dir="${EPREFIX}${rundir}"

		-Ddefault_library=$(multilib_native_usex static-libs both shared)

		$(meson_feature apparmor)
		-Dasserts=false # TODO
		-Dchecks=false # TODO
		$(meson_use debug stats)
		$(meson_use debug verbose_mode)
		-Ddbus_user=messagebus
		-Dkqueue=disabled
		$(meson_feature kernel_linux inotify)
		$(meson_native_use_feature doc doxygen_docs)
		$(meson_native_enabled xml_docs) # Controls man pages
		$(meson_use dinit traditional_activation)

		-Dinstalled_tests=false
		$(meson_native_true message_bus) # TODO: USE=daemon?
		$(meson_feature test modular_tests)
		-Dqt_help=disabled

		$(meson_native_true tools)

		$(meson_native_use_feature elogind)
		$(meson_native_use_feature systemd)
		$(meson_use systemd user_session)
		$(meson_native_use_feature X x11_autolaunch)
		$(meson_native_use_feature valgrind)

		# libaudit is *only* used in DBus wrt SELinux support, so disable it if
		# not on an SELinux profile.
		$(meson_native_use_feature selinux)
		$(meson_native_use_feature selinux libaudit)

		-Dsession_socket_dir="${EPREFIX}"/tmp
		-Dsystem_pid_file="${EPREFIX}${rundir}"/dbus.pid
		-Dsystem_socket="${EPREFIX}${rundir}"/dbus/system_bus_socket
		-Dsystemd_system_unitdir="$(systemd_get_systemunitdir)"
		-Dsystemd_user_unitdir="$(systemd_get_userunitdir)"
	)

	if [[ ${CHOST} == *-darwin* ]]; then
		emesonargs+=(
			-Dlaunchd=enabled
			-Dlaunchd_agent_dir="${EPREFIX}"/Library/LaunchAgents
		)
	fi

	meson_src_configure
}

multilib_src_compile() {
	# After the compile, it uses a selinuxfs interface to
	# check if the SELinux policy has the right support
	use selinux && addwrite /selinux/access

	meson_src_compile
}

multilib_src_test() {
	# DBUS_TEST_MALLOC_FAILURES=0 to avoid huge test logs
	# https://gitlab.freedesktop.org/dbus/dbus/-/blob/master/CONTRIBUTING.md#L231
	DBUS_TEST_MALLOC_FAILURES=0 DBUS_VERBOSE=1 virtx meson_src_test

}

multilib_src_install_all() {
	if use dinit; then
		# system session bus
		insinto /etc/dinit.d
		doins "${FILESDIR}"/dinit/dbus
		doins "${FILESDIR}"/dinit/dbus-pre

		exeinto /usr/lib/dinit
		newexe "${FILESDIR}"/dinit/dbus.script dbus

		exeinto /usr/lib/dinit/pre
		newexe "${FILESDIR}"/dinit/dbus-pre.script dbus

		dodir /etc/dinit.d/boot.d
		dosym /etc/dinit.d/dbus /etc/dinit.d/boot.d/dbus

		# user session bus
		insinto /etc/dinit.d/user
		newins "${FILESDIR}"/dinit/dbus.user dbus

		exeinto /usr/lib/dinit/user
		newexe "${FILESDIR}"/dinit/dbus.user.script dbus

		dodir /usr/lib/dinit.d/user/boot.d
		dosym /etc/dinit.d/user/dbus /usr/lib/dinit.d/user/boot.d/dbus
	fi

	newinitd "${T}"/dbus.initd dbus
	exeinto /etc/user/init.d
	newexe "${FILESDIR}/dbus.user.initd" dbus

	if use X; then
		# dbus X session script (bug #77504)
		# turns out to only work for GDM (and startx). has been merged into
		# other desktop (kdm and such scripts)
		exeinto /etc/X11/xinit/xinitrc.d
		newexe "${FILESDIR}"/80-dbus-r1 80-dbus
	fi

	# Needs to exist for dbus sessions to launch
	keepdir /usr/share/dbus-1/services
	keepdir /etc/dbus-1/{session,system}.d
	# machine-id symlink from pkg_postinst()
	keepdir /var/lib/dbus
	# Let the init script create the /var/run/dbus directory
	rm -rf "${ED}"/{,var/}run

	# bug #761763
	rm -rf "${ED}"/usr/lib/sysusers.d

	dodoc AUTHORS NEWS README doc/TODO
	readme.gentoo_create_doc

	mv "${ED}"/usr/share/doc/dbus/* "${ED}"/usr/share/doc/${PF}/ || die
	rm -rf "${ED}"/usr/share/doc/dbus || die
}

pkg_postinst() {
	readme.gentoo_print_elog

	if use systemd; then
		tmpfiles_process dbus.conf
	fi

	if ! use dinit; then
		# Ensure unique id is generated and put it in /etc wrt bug #370451 but symlink
		# for DBUS_MACHINE_UUID_FILE (see tools/dbus-launch.c) and reverse
		# dependencies with hardcoded paths (although the known ones got fixed already)
		# TODO: should be safe to remove at least the ln because of the above tmpfiles_process?
		dbus-uuidgen --ensure="${EROOT}"/etc/machine-id
		ln -sf "${EPREFIX}"/etc/machine-id "${EROOT}"/var/lib/dbus/machine-id
	fi

	if [[ ${CHOST} == *-darwin* ]]; then
		local plist="org.freedesktop.dbus-session.plist"
		elog
		elog "For MacOS/Darwin we now ship launchd support for dbus."
		elog "This enables autolaunch of dbus at session login and makes"
		elog "dbus usable under MacOS/Darwin."
		elog
		elog "The launchd plist file ${plist} has been"
		elog "installed in ${EPREFIX}/Library/LaunchAgents."
		elog "For it to be used, you will have to do all of the following:"
		elog " + cd ~/Library/LaunchAgents"
		elog " + ln -s ${EPREFIX}/Library/LaunchAgents/${plist}"
		elog " + logout and log back in"
		elog
		elog "If your application needs a proper DBUS_SESSION_BUS_ADDRESS"
		elog "specified and refused to start otherwise, then export the"
		elog "the following to your environment:"
		elog " DBUS_SESSION_BUS_ADDRESS=\"launchd:env=DBUS_LAUNCHD_SESSION_BUS_SOCKET\""
	fi
}
