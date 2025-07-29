# Unofficial Gentoo overlay for Dinit

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

## Overlay priority

Gentoo has a mechanism to define which ebuild is selected in the event a package has the same version number in two different repositories, as detailed in the [Gentoo wiki](https://wiki.gentoo.org/wiki//etc/portage/repos.conf).\
The ebuild in the repository with the highest priority will be selected.

When using the dinit overlay, ebuilds in this overlay should take precedence over the ebuilds in the main Gentoo repository, so you need to set the priorities accordingly.

Check the current priority in `/etc/portage/repos.conf/gentoo.conf`:
```text
priority = -1000
```

**Note** *-1000* is the default value, but you may have changed it previously.

The `dinit.conf` file in the base of this repository uses a priority value of *10*.\
The value in the `dinit` section of the relevant repo config file needs to be higher than in the `gentoo.conf` file - if it isn't, then modify one or both so it is.
