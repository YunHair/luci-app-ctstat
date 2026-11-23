include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-ctstat
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0-or-later
PKG_MAINTAINER:=YunHair

include $(INCLUDE_DIR)/package.mk

define Package/luci-app-ctstat
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI app for accurate per-client traffic statistics (conntrack)
  DEPENDS:=+luci-base +rpcd +jsonfilter +ip-full +uclient-fetch +ca-bundle
  PKGARCH:=all
endef

define Package/luci-app-ctstat/description
 Accurate per-client, per-application and per-destination traffic statistics
 for OpenWrt, based on conntrack byte counters. Works with NSS/PPE hardware
 offload and on pure nftables/fw4 firmware. All runtime dependencies are
 firewall-independent LuCI / iproute2 / busybox components.
 Optional extras (install manually): tc-tiny (shaper counters), gawk (lower
 RAM), tcpdump (DNS names), socat + netifyd (DPI application names).
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/luci-app-ctstat/conffiles
/etc/config/ctstat
endef

define Package/luci-app-ctstat/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) $(CURDIR)/root/etc/config/ctstat $(1)/etc/config/ctstat
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(CURDIR)/root/etc/init.d/ctstat $(1)/etc/init.d/ctstat
	$(INSTALL_DIR) $(1)/etc/sysctl.d
	$(INSTALL_DATA) $(CURDIR)/root/etc/sysctl.d/99-ctstat.conf $(1)/etc/sysctl.d/99-ctstat.conf
	$(INSTALL_DIR) $(1)/usr/libexec
	for f in $(CURDIR)/root/usr/libexec/*; do \
		[ -f "$$$$f" ] || continue; \
		$(INSTALL_BIN) "$$$$f" $(1)/usr/libexec/; \
	done
	$(INSTALL_DIR) $(1)/usr/libexec/rpcd
	$(INSTALL_BIN) $(CURDIR)/root/usr/libexec/rpcd/luci.ctstat $(1)/usr/libexec/rpcd/luci.ctstat
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/luci/menu.d/luci-app-ctstat.json $(1)/usr/share/luci/menu.d/luci-app-ctstat.json
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DATA) $(CURDIR)/root/usr/share/rpcd/acl.d/luci-app-ctstat.json $(1)/usr/share/rpcd/acl.d/luci-app-ctstat.json
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ctstat
	$(INSTALL_DATA) $(CURDIR)/htdocs/luci-static/resources/view/ctstat/overview.js $(1)/www/luci-static/resources/view/ctstat/overview.js
	$(INSTALL_DATA) $(CURDIR)/htdocs/luci-static/resources/view/ctstat/config.js $(1)/www/luci-static/resources/view/ctstat/config.js
endef

define Package/luci-app-ctstat/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	# git checkouts lose the exec bit when the mode is not recorded, and rpcd
	# silently ignores a non-executable plugin - the page then fails with
	# "Object not found". Force it at install time.
	chmod 755 /usr/libexec/rpcd/luci.ctstat 2>/dev/null
	chmod 755 /usr/libexec/ctstat-* 2>/dev/null
	/etc/init.d/rpcd reload 2>/dev/null
	rm -f /tmp/luci-indexcache* 2>/dev/null
	rm -rf /tmp/luci-modulecache 2>/dev/null
	/etc/init.d/ctstat enable 2>/dev/null
	/etc/init.d/ctstat restart 2>/dev/null
}
exit 0
endef

define Package/luci-app-ctstat/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] || {
	/etc/init.d/ctstat stop 2>/dev/null
	/etc/init.d/ctstat disable 2>/dev/null
}
exit 0
endef

$(eval $(call BuildPackage,luci-app-ctstat))

define Package/luci-i18n-ctstat-zh-cn
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Translations
  TITLE:=Chinese (zh-cn) for luci-app-ctstat
  DEPENDS:=+luci-app-ctstat
  PKGARCH:=all
endef

define Package/luci-i18n-ctstat-zh-cn/description
 Simplified Chinese translation for luci-app-ctstat.
endef

define Package/luci-i18n-ctstat-zh-cn/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(CURDIR)/root/usr/lib/lua/luci/i18n/ctstat.zh-cn.lmo $(1)/usr/lib/lua/luci/i18n/ctstat.zh-cn.lmo
endef

$(eval $(call BuildPackage,luci-i18n-ctstat-zh-cn))
