# Unofficial Gentoo overlay for Dinit

## Contents

1. [Introduction](#introduction)
2. [Installation](#installing-the-overlay)
   1. [Manually](#manually)
   2. [Overlay Priority](#overlay-priority)

## Introduction

Dinit is a portable, dependency-based service manager and init system, designed with the goals of clean design, robustness, usability, and minimal complexity. Unlike traditional rc systems, Dinit supervises services and actively tracks their states, similar to tools like Systemd, S6, and Runit.

It supports service dependencies to control startup and shutdown ordering, as well as explicit startup ordering without dependency links. Additional features include oneshot and scripted services, readiness notifications, basic socket activation, and more. Dinit is intended to integrate with existing system software rather than replace it.

This overlay provides ebuilds for using Dinit on Gentoo. It enables installation, configuration, and integration of Dinit as an alternative to OpenRC or Systemd.

## Installing the overlay

### Manually

To install this overlay using Portage's built-in repos.conf mechanism, ensure that the `repos.conf` directory exists:
```shell
mkdir -p /etc/portage/repos.conf
```

Next, get the `dinit.conf` file from the base of this repository:
```shell
wget https://raw.githubusercontent.com/TintedKiwi/dinit-overlay/refs/heads/main/dinit.conf -O /etc/portage/repos.conf/dinit.conf
```

Lastly, use `emaint` to sync the repo:
```shell
emaint sync -r dinit
```

### Overlay priority

Gentoo has a mechanism to define which ebuild is selected in the event a package has the same version number in two different repositories, as detailed in the [Gentoo wiki](https://wiki.gentoo.org/wiki//etc/portage/repos.conf).
The ebuild in the repository with the highest priority will be selected.

When using the dinit overlay, ebuilds in this overlay should take precedence over the ebuilds in the main Gentoo repository, so you need to set the priorities accordingly.
The Gentoo ebuild repository defaults to a priority value of **-1000**, while this overlay sets a default priority of **10** in its `dinit.conf` file.
