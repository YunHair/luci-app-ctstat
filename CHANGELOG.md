# Changelog

## 1.0.0-r1

全新仓库起点：重新 fork `m0g13r/luci-app-traffic-chart` main（`2353fc4`），
包名改为 `luci-app-ctstat`，版本号从 1.0.0 开始。

- **纯 fw4**：移除 `sqm-scripts`、`tc`（tc-full）、`conntrack` 命令行、`gawk`、
  `tcpdump` 硬依赖；`Depends` 仅剩 `luci-base rpcd jsonfilter ip-full
  uclient-fetch ca-bundle`，安装不再拉入任何 iptables/fw3 组件。
- **清除 fw3 遗留**：删除随包的 `nss-*.qos` SQM 分类脚本、`*-migrate` 迁移脚本，
  以及 `bulk_bytes` / `reset_ct_marks` / `dns_redirect` / `ttl_fix` 死配置和
  设置页的 "SQM classifier" 区块。
- 统一服务名、UCI 配置、ACL、菜单、rpcd object 为 `ctstat`。
- 菜单合并为 **服务 → 流量统计**，子菜单 1「流量图表」（默认）、子菜单 2「设置」。
- 设备 / 应用 / 目标排行改单列，每行一个条目，名称完整显示不截断。
- 新增中文翻译包 `luci-i18n-ctstat-zh-cn`（218 条 UI 文案）。
- 修复 rpcd 插件未随包安装导致的 "Object not found"，以及 `/proc/uptime`
  在部分 procfs 上误判数据 stale。
- 数据源 `/proc/net/nf_conntrack` 差分 + `nf_conntrack_acct=1`，
  NSS/PPE/ECM 硬件加速下按 conntrack 回写计数，统计不受卸载影响。
