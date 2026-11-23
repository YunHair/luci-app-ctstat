# Changelog

## 1.2.0-r2
- **Fixed the `.ipk` container format.** The r1 packages were built as Debian `ar` archives, but
  OpenWrt's opkg expects a gzip'ed outer tar (`./debian-binary`, `./data.tar.gz`,
  `./control.tar.gz`), exactly like `scripts/ipkg-build`. On a router this surfaced as
  `pkg_init_from_file: Malformed package file`. The builder now emits GNU tar + `gzip -n`, and
  `Installed-Size` is the compressed `data.tar.gz` size, matching upstream `ipkg-build`.
  Verified end-to-end with the real opkg from OpenWrt 23.05.5 (x86_64 rootfs).
- No source changes versus 1.2.0-r1.

## 1.2.0-r1 (YunHair fork)
- **fw4 only**: removed every legacy firewall3/iptables dependency. The package now hard-depends on
  `firewall4` + `nftables` and the postinstall warns when `/sbin/fw4` is missing. The bundled
  `nss-trafficchart.qos` classifier only writes nftables (`inet qos_custom`); no `iptables`, `ip6tables`,
  `luci-app-firewall` or `fw3` include script is used anywhere.
- **Unified menu**: one top-level LuCI menu `traffic-chart` with the submenus `Charts` and `Settings`.
  The old `Network -> Traffic Chart` entry and the hidden settings view are gone; the views moved to
  `view/traffic-chart/chart.js` and `view/traffic-chart/settings.js`.
- **Mobile layout**: on screens up to 760 px every item occupies its own row. The donut and its legend
  are stacked, the legend becomes a single column, the tab bar scrolls horizontally, the toolbar buttons
  share one full-width row, shaper health lines wrap instead of being clipped, and the busiest-flows table
  turns into one card per flow with a `label: value` line per field.
- **Translations**: new `po/zh_Hans` and `po/zh_Hant` catalogs, built as `luci-i18n-traffic-chart-zh-cn`
  and `luci-i18n-traffic-chart-zh-tw`.
- Version bumped to 1.2.0, package architecture `all`.

## 1.1.0-r21
- Corrected package dependencies for the intended OpenWrt 21 release: luci-base, rpcd, sqm-scripts, conntrack, jsonfilter, tc, gawk, ip, tcpdump, uclient-fetch and ca-bundle.
- Renamed the SQM script `nss-rk.qos` -> `nss-trafficchart.qos` (version 0.9.4). SQM entries in
  `/etc/config/sqm` are migrated by the postinstall (`trafficchart-migrate`); SQM must be restarted by hand.
- Temporary nft file is now `/tmp/nss-trafficchart-qos.nft`.
- License: GPL-2.0-or-later, maintainer M0g13r. Added LICENSE, README, SPDX headers.
- Package Makefile with correct file modes, conffile `/etc/config/trafficchart`, enable/start on install,
  stop/disable on removal.

## 1.1.0-r11
- Previous state (no packaging).
