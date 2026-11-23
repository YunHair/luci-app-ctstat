# OpenWrt Traffic Chart feed (fw4 fork)

Package feed for **luci-app-traffic-chart**: live traffic chart for LuCI (per application, device and
destination, busiest flows, shaper health, history) plus the SQM script `nss-trafficchart.qos` for
Qualcomm NSS hardware offload.

This is the **YunHair** fork of [m0g13r/luci-app-traffic-chart](https://github.com/m0g13r/luci-app-traffic-chart).
It is **fw4 only** (firewall4 + nftables, no fw3/iptables), ships a single top-level menu
`traffic-chart` with `Charts` / `Settings` submenus, a phone layout where every item uses its own row,
and Simplified/Traditional Chinese translations.

Maintainer: YunHair - License: GPL-2.0-or-later

| Package | Version |
|---|---|
| [luci-app-traffic-chart](luci-app-traffic-chart/) | 1.2.0-r3 |
| luci-i18n-traffic-chart-zh-cn | 1.2.0-r3 |
| luci-i18n-traffic-chart-zh-tw | 1.2.0-r3 |

Details, settings and troubleshooting: [luci-app-traffic-chart/README.md](luci-app-traffic-chart/README.md),
changes: [CHANGELOG](luci-app-traffic-chart/CHANGELOG.md).

## Use as feed (build system)
Add to `feeds.conf` (or `feeds.conf.default`):

```
src-git trafficchart https://github.com/YunHair/luci-app-traffic-chart.git
```

Then:

```sh
./scripts/feeds update trafficchart
./scripts/feeds install -a -p trafficchart
make menuconfig        # LuCI -> 3. Applications -> luci-app-traffic-chart
make package/luci-app-traffic-chart/compile V=s
```

The `po/zh_Hans` and `po/zh_Hant` catalogs are built automatically by `luci.mk` into
`luci-i18n-traffic-chart-zh-cn` and `luci-i18n-traffic-chart-zh-tw`.

## Install on the router
Copy the built package (`.ipk` or `.apk`) to the router and install it with `opkg install` or `apk add --allow-untrusted`.
Afterwards open **traffic-chart -> Charts** in LuCI (settings live in **traffic-chart -> Settings**).
Requires OpenWrt 22.03 or newer (firewall4). When upgrading from the old `nss-rk.qos`, restart SQM once
(`/etc/init.d/sqm restart`); the SQM entry is migrated automatically.
