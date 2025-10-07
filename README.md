# dinit-overlay

*Gentoo overlay for Dinit, a lightweight init and service manager.*

## Table of Contents

1. [Introduction](#-introduction)
2. [Quick Start](#-quick-start)
3. [Switching / Replacing Your Init](#-switching--replacing-your-init)
   1. [Using Dinit as a Service Manager Only](#-using-dinit-as-a-service-manager-only)
   2. [Booting into Dinit Without Replacing Your Init System](#-booting-into-dinit-without-replacing-your-init-system)
   3. [Fully Replacing Your Init System with Dinit](#fully-replacing-your-init-system-with-dinit)
4. [Profiles and Configuration](#-profiles-and-configuration)
5. [Overlay Behavior & Masking Considerations](#-overlay-behavior--masking-considerations)

## Introduction

This overlay provides Gentoo ebuilds for [Dinit](https://github.com/davmac314/dinit), a dependency-based init and service manager. It supports service readiness notifications, dependency ordering, and can be used both as a full init system or a standalone service manager.

## Quick Start

Add the overlay manually:

```shell
mkdir -p /etc/portage/repos.conf
wget https://raw.githubusercontent.com/TintedKiwi/dinit-overlay/main/dinit.conf -O /etc/portage/repos.conf/dinit.conf
emaint sync -r dinit
```

Ensure it has higher priority than the main Gentoo tree (default is `priority = 10`).

## Switching / Replacing Your Init

Dinit can be used either:

- as a **standalone service manager**, alongside your existing init system
- as a **full init system**, running as PID 1

### Using Dinit as a Service Manager Only

To install Dinit **without init capabilities**, disable both the `init` and `symlink` USE flags:

```shell
echo "sys-apps/dinit -init -symlink" > /etc/portage/package.use/dinit
emerge --ask sys-apps/dinit
```

In this mode:

- Dinit cannot be used as PID 1
- It won’t install any system-level init utilities (`halt`, `reboot`, etc.)
- It can be run manually alongside another init system (OpenRC, Systemd, etc.)

### Booting into Dinit Without Replacing Your Init System

To boot into Dinit temporarily (for testing), enable the `init` USE flag but leave `symlink` disabled:

```shell
echo "sys-apps/dinit init -symlink" > /etc/portage/package.use/dinit
emerge --ask sys-apps/dinit
```

Then pass this to your kernel command line:

```text
init=/sbin/dinit-init
```

In this mode:

- Dinit can run as PID 1 without removing other init systems
- Utilities like `dinit-halt`, `dinit-reboot`, etc. will be installed with a prefix to avoid conflicts
- This is ideal for testing before fully switching

### Fully Replacing Your Init System with Dinit

To make Dinit your primary init system, enable both the `init` and `symlink` USE flags:

```shell
echo "sys-apps/dinit init symlink" > /etc/portage/package.use/dinit
emerge --ask sys-apps/dinit
```

This will:

- Build Dinit with PID 1 support
- Symlink `/sbin/init` → `dinit-init`
- Uninstall other init systems and service managers

⚠️ Ensure your Dinit services are configured and enabled before rebooting.

## Profiles and Configuration

This overlay provides Dinit-specific system profiles to simplify installation, similar to those available for OpenRC or Systemd.

- List available profiles:
```shell
eselect profile list
```

- Switch to a Dinit profile:
```shell
eselect profile set <profile-number>
```

These profiles configure system defaults to suit Dinit, including USE flags and service dependencies.

## Overlay Behavior & Masking Considerations

Some packages in this overlay also exist in the Gentoo main tree. To avoid conflicts:

- Use `package.mask` and `package.unmask` as needed
- Set overlay priority to ensure dinit-overlay packages are used
- Review ebuild changes when syncing the Gentoo repo
