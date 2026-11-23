include $(TOPDIR)/rules.mk

PKG_VERSION:=1.2.0
PKG_RELEASE:=2
PKG_LICENSE:=GPL-2.0-or-later
PKG_MAINTAINER:=YunHair

LUCI_NAME:=luci-app-traffic-chart
LUCI_MAINTAINER:=YunHair
LUCI_TITLE:=Live traffic chart for fw4 (nftables + conntrack + shaper counters)
LUCI_DESCRIPTION:=Live and historical traffic chart per application, device and destination. \
	Reads conntrack and qdisc counters, independent of the shaper in use; includes the \
	nss-trafficchart.qos SQM classifier. Requires firewall4/nftables (fw4 only, no fw3/iptables). \
	Optional: socat + netifyd for application names.
# fw4 only: firewall4 pulls in nftables and kmod-nft-core; the nft CLI is used by the SQM
# classifier. There is no iptables/fw3 dependency left in this package.
LUCI_DEPENDS:=+luci-base +rpcd +firewall4 +nftables +sqm-scripts +conntrack +jsonfilter +tc +gawk +ip +tcpdump +uclient-fetch +ca-bundle
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

define Package/luci-app-traffic-chart/conffiles
/etc/config/trafficchart
endef

define Package/luci-app-traffic-chart/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/rpcd reload 2>/dev/null
	rm -f /tmp/luci-indexcache* /tmp/luci-modulecache/* 2>/dev/null
	/usr/libexec/trafficchart-migrate
	# fw4 only: warn instead of silently running on a firewall3 system
	if [ ! -x /sbin/fw4 ] && [ ! -x /usr/sbin/fw4 ]; then
		logger -t trafficchart "WARNING: firewall4 (fw4) not found - luci-app-traffic-chart needs fw4/nftables, firewall3/iptables is not supported"
	fi
	/etc/init.d/trafficchart enable
	/etc/init.d/trafficchart restart
}
exit 0
endef

define Package/luci-app-traffic-chart/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/trafficchart stop 2>/dev/null
	/etc/init.d/trafficchart disable 2>/dev/null
}
exit 0
endef

# call BuildPackage - OpenWrt buildroot signature
