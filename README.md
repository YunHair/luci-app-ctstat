# luci-app-ctstat 1.0.0

纯 nftables / fw4 的 LuCI 流量统计插件：按**客户端 / 应用 / 目标地址**统计实时与历史流量，
在 **NSS / PPE / ECM 硬件加速开启时依然准确**。

Fork 自 [m0g13r/luci-app-traffic-chart](https://github.com/m0g13r/luci-app-traffic-chart)
`main` 分支（commit `2353fc4`，2026-10-30），包名改为 `luci-app-ctstat`，版本号从 **1.0.0** 开始。

## 为什么硬件加速下也准

数据源是 `/proc/net/nf_conntrack` 的 `bytes=` 计数（`net.netfilter.nf_conntrack_acct=1`，
由 `/etc/sysctl.d/99-ctstat.conf` 保证）。ECM/NSS 卸载连接时会把收发字节数
`atomic64_add` 回写到 conntrack 的 acct，因此报文不经过 netfilter 也不漏计。
采集器逐轮做**差分**（而非读总数），连接过期清零、端口复用都不会重复计数。

## 纯 fw4 改造（相对上游）

| 项目 | 上游 | 本版 |
|---|---|---|
| 硬依赖 `sqm-scripts` | 有（拖入 `iptables`、`iptables-mod-ipopt`、`kmod-sched-cake`） | **移除** |
| 硬依赖 `tc`（解析成 `tc-full`） | 有（拖入 `libxtables12`） | **移除** |
| 硬依赖 `conntrack` 命令行 | 有 | **移除**（只读 `/proc` 文件） |
| 硬依赖 `gawk`、`tcpdump` | 有 | 改为可选增强 |
| 随包 SQM 分类脚本 `nss-*.qos` + `migrate` | 有 | **删除文件** |
| SQM 死配置与设置页区块（`bulk_bytes` / `reset_ct_marks` / `dns_redirect` / `ttl_fix`） | 有 | **删除** |
| `iptables` / `ip6tables` / `nft` 命令调用 | 无 | 无 |
| 最终 `Depends` | 含 fw3 链 | `luci-base rpcd jsonfilter ip-full uclient-fetch ca-bundle` |

> 说明：界面里出现的 "SQM rate" / "整形器带宽" 指 tc qdisc 的配置速率
> （采集器 JSON 字段 `sqm_kbit`），仅用于计算百分比与速率图，来自 iproute2，
> 是 fw4 原生能力，与 firewall3/iptables 无关。不装 `tc-tiny` 时该值为 0，
> 客户端累计统计不受影响。

## 界面

- 菜单：合并为 **服务 → 流量统计**，两个子菜单：**流量图表**（默认打开）、**设置**。
- 设备 / 应用 / 目标三个排行均为**单列**，每行一个条目，名称完整显示不截断。
- 历史：24 小时 / 周 / 月 / 年，可持久化到 U 盘或网络路径。
- 中文翻译包 `luci-i18n-ctstat-zh-cn`，覆盖 218 条 UI 文案。

## 安装

opkg 固件（24.10 及同代）：

```sh
opkg install luci-app-ctstat_1.0.0-r1_all.ipk
opkg install luci-i18n-ctstat-zh-cn_1.0.0-r1_all.ipk   # 翻译包，顺序不能反
```

apk 固件（25.12+）：

```sh
apk add --allow-untrusted luci-app-ctstat-1.0.0-r1.apk
apk add --allow-untrusted luci-i18n-ctstat-zh-cn-1.0.0-r1.apk
```

装完刷新页面，打开 **服务 → 流量统计**。postinst 会自动启用服务、
重载 rpcd、清 LuCI 缓存。升级会保留 `/etc/config/ctstat`。

## 可选增强（均不拉入 iptables）

```sh
opkg install tc-tiny gawk tcpdump
opkg install socat netifyd     # DPI 应用名（较重，一般不需要）
```

| 组件 | 不装的后果 |
|---|---|
| `tc-tiny` | 速率走 sysfs、无整形器丢包/ECN/未归因流量；客户端累计仍准 |
| `gawk` | 用 busybox awk（插件自带 48 MB 内存守卫） |
| `tcpdump` | 应用名显示为 `[tcp/443]` 形式 |
| `socat` + `netifyd` | 无 DPI 应用名，按端口推断 |

## 产物

| 格式 | 文件 |
|---|---|
| ipk 主包 | `luci-app-ctstat_1.0.0-r1_all.ipk` |
| ipk 翻译包 | `luci-i18n-ctstat-zh-cn_1.0.0-r1_all.ipk` |
| apk 主包 | `luci-app-ctstat-1.0.0-r1.apk` |
| apk 翻译包 | `luci-i18n-ctstat-zh-cn-1.0.0-r1.apk` |

CI：推送 `v*` tag 自动用 24.10 / 25.12 SDK 编译 ipk 与 apk（含翻译包）并发布 Release。

## 边界

- 不要与旧版 `luci-app-ctstat`（1.0-r1/r2/r3）并行运行，两者都会扫 conntrack。
- 翻译包依赖主包。
- 上游 GPL-2.0-or-later，改造部分同许可。
