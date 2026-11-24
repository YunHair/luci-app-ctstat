# luci-app-ctstat 1.3.0（纯 fw4）

OpenWrt LuCI 实时流量统计：按**应用 / 设备 / 目标地址**统计流量，显示最繁忙的连接、整形器健康状态
（丢包、ECN 标记、队列积压）以及历史曲线（24 小时 / 周 / 月 / 年），历史可持久化到 U 盘、SD 卡或内置闪存。

本仓库是 [m0g13r/luci-app-traffic-chart](https://github.com/m0g13r/luci-app-traffic-chart) 的 fork：
**YunHair/luci-app-ctstat**。1.2.0 及更早的版本叫 `luci-app-traffic-chart`，1.3.0 起
包名、模块名、配置名统一改为 `ctstat`（connection statistics）。

## 与上游的差异

| 项目 | 上游 1.1.0-r21 | 本 fork 1.3.0 |
|---|---|---|
| 名称 | `luci-app-traffic-chart` / `trafficchart` | **`luci-app-ctstat` / `ctstat`**，配置、服务、rpcd 对象、SQM 分类器同步改名，安装时自动迁移旧设置与历史 |
| 防火墙 | 依赖里没有明确声明，文档仍提到 iptables | **纯 fw4**：硬依赖 `firewall4` + `nftables`，安装时检测 `/sbin/fw4`，不再有任何 fw3 / iptables 依赖或调用 |
| 主菜单 | `网络 → Traffic Chart`，设置页是隐藏菜单 | **`服务 → 流量监控`**，内含 `流量图表` 和 `设置` 两个子菜单 |
| 手机显示 | 图例两列、流量表 7 列，手机上拥挤 | 手机上**每个项目独占一行**（列模板由 JS 直接写成内联样式，不依赖媒体查询）：圆环与图例上下排列、图例单列、标签栏横向滚动、工具栏整行按钮、最繁忙连接改为每条一张卡片 |
| 设备列表 | 尾部设备折叠为“其他” | 每台设备单独一行、单独扇区，槽位数跟随 `attr_max_devices`（默认 64，上限 256） |
| 服务库更新 | 只连 GitHub release | 官方源 + 4 个公开镜像回退，支持自定义 URL；失败原因按镜像分别报告（DNS / 超时 / TLS / 404），不再一律提示“缺 ca-bundle” |
| 翻译 | 无 | 简体中文、繁体中文翻译包（`luci-i18n-ctstat-zh-cn` / `zh-tw`） |
| 版本 | 1.1.0-r21 | 1.3.0-r1，架构 `all` |

> 上游代码本身已经用 nftables（`nss-trafficchart.qos` 写 `inet qos_custom` 表），并不存在 iptables 规则生成逻辑。
> 本 fork 做的是把 fw3 时代的残留（依赖声明、文档表述、安装环境假设）彻底清掉，并从打包层面强制 fw4。

## 运行要求

- OpenWrt **22.03 或更新**（firewall4 / nftables），不支持 firewall3 的 21.02 及更早版本。
- 依赖：`luci-base`、`rpcd`、`firewall4`、`nftables`、`conntrack`、`jsonfilter`、
  `tc-tiny`、`ip-tiny`、`gawk`、`tcpdump`、`uclient-fetch`、`ca-bundle`。
  依赖闭包中**不含** `iptables` / `ip6tables` / `libxtables*` / `tc-mod-iptables` / `firewall3`。
- 可选：`sqm-scripts`。`nss-ctstat.qos` 分类器随包安装到 `/usr/lib/sqm/`，装了 SQM 后可在
  SQM 设置里选择它；主程序和图表不依赖 SQM。注意 OpenWrt 23.05 的 `sqm-scripts` 自身依赖
  `iptables`，纯 fw4 系统若不想引入 iptables，请不要安装 SQM。
- 可选：`socat` + `netifyd`（带 `[socket] listen_path`）用于应用名称识别；没有时按协议/端口命名。

## 安装

```sh
opkg update
opkg install luci-app-ctstat_1.3.0-r1_all.ipk
opkg install luci-i18n-ctstat-zh-cn_1.3.0-r1_all.ipk   # 中文界面（可选）
```

安装后 postinst 会迁移旧配置、启用并启动 `ctstat` 服务、重载 rpcd；刷新 LuCI 即可看到新菜单。

### 从 luci-app-traffic-chart 升级

两个包名不同，opkg 会把它们当成两个独立软件包。推荐先卸载旧包再装新包：

```sh
opkg remove luci-i18n-traffic-chart-zh-cn luci-i18n-traffic-chart-zh-tw   # 先删翻译包
opkg remove luci-app-traffic-chart                                        # 再删主包
opkg install luci-app-ctstat_1.3.0-r1_all.ipk
```

opkg 记录了依赖关系，先删主包会提示 `is depended upon by luci-i18n-traffic-chart-*`；
若确实只想删主包，用 `opkg remove --force-depends luci-app-traffic-chart`。

即使不卸载，`ctstat-migrate` 也会在 postinst 阶段停用旧服务、迁移
`/etc/config/trafficchart` → `/etc/config/ctstat`、`/etc/trafficchart-*` → `/etc/ctstat-*`，
把指向内置闪存的存储路径改为 `/etc/ctstat-data`（`/mnt` 下的自定义路径名保持不变，避免找不到目录而丢历史），
并删除旧的菜单、视图和 libexec 脚本，避免出现重复菜单与两个聚合进程。之后仍建议执行一次
`opkg remove luci-app-traffic-chart` 让 opkg 数据库保持一致。

已在 OpenWrt 23.05.5 x86_64 rootfs（内核 5.15.167）中用真实 `opkg` 完整安装验证：opkg 自动拉取的
10 个额外包为 `conntrack`、`kmod-sched-core`、`tc-tiny`、`ip-tiny`、`terminfo`、`libncurses6`、
`libreadline8`、`gawk`、`libpcap1`、`tcpdump`，无任何 iptables / xtables / SQM / firewall3 包。

## 菜单结构

```
服务 (Services)
└── 流量监控 (Traffic Monitor)
    ├── 流量图表  应用 / 设备 / 目标 / 连接 / 历史
    └── 设置      采集、DNS、告警、历史存储、SQM 分类器、内存守护
```

- `流量图表` 需要只读 ACL `luci-app-ctstat`。
- `设置` 需要管理 ACL `luci-app-ctstat-admin`（可重启服务、清空历史、更新域名库）。
- `设备` 视图为每台设备单独分配一行和一个圆环扇区，槽位数读取设置里的**最大候选设备数**
  （`attr_max_devices`，默认 64，界面上限 256），不会把尾部设备折叠成“其他”。

## 手机访问

手机 / 触屏设备上自动切换为单列布局。图例列数由脚本以内联样式写入（手机上 `minmax(0, 1fr)`），
不依赖 `@media` 是否命中——浏览器把页面按 980 px “桌面版网站”排版、或缓存了旧样式表时同样生效：

- 上传 / 下载两个圆环面板上下排列，**应用 / 设备 / 目标三个列表每项占一行**，不会出现两项并排；
- 顶部标签栏（应用 / 设备 / 目标 / 连接 / 历史）横向滑动，不再换行挤压；
- 导出、设置按钮占满一行，方便点击；
- “最繁忙的连接”表格变为卡片：每条连接一张卡片，设备、应用、目标、端口、下载、上传、总量各占一行，
  左侧为字段名、右侧为数值；
- 整形器健康信息允许换行，不再被固定高度截断。

## 组件

| 部分 | 安装位置 |
|---|---|
| 聚合守护进程（conntrack、历史） | `/usr/libexec/ctstat-agg`，服务 `/etc/init.d/ctstat` |
| netifyd 应用名称 | `/usr/libexec/ctstat-apps` |
| 整形器识别与计数器 | `/usr/libexec/ctstat-common`、`ctstat-tc` |
| 局域网设备识别、IPv6 前缀 | `/usr/libexec/ctstat-hosts`、`ctstat-v6prefixes` |
| 持久化辅助 | `/usr/libexec/ctstat-persist-exec` |
| 旧版迁移 | `/usr/libexec/ctstat-migrate` |
| rpcd 插件与 ACL | `/usr/libexec/rpcd/luci.ctstat`、`/usr/share/rpcd/acl.d/luci-app-ctstat.json` |
| LuCI 页面 | `/www/luci-static/resources/view/ctstat/chart.js`、`settings.js` |
| 菜单 / 翻译 | `/usr/share/luci/menu.d/luci-app-ctstat.json`、`/usr/lib/lua/luci/i18n/ctstat.*.lmo` |
| NSS SQM 脚本 | `/usr/lib/sqm/nss-ctstat.qos`（+ `.help`） |
| 配置 | `/etc/config/ctstat`（升级保留） |
| 运行时数据 | `/var/run/ctstat/`（内存） |

## 配置项

配置文件 `/etc/config/ctstat` 的 `global` 段，或 LuCI 的 **流量监控 → 设置**。
保存会重启聚合进程：累计总量清零，历史保留。

| 选项 | 默认值 | 含义 |
|---|---|---|
| `enabled` | 1 | 启用采集 |
| `apps` | 1 | 通过 netifyd 识别应用名（需要 socat + netifyd） |
| `dns_names` | 1 | 通过 tcpdump 监听明文 DNS，作为域名/应用名回退 |
| `backend` | auto | `auto`、`nss` 或 `generic` |
| `interval` | 4 | 两次 conntrack 扫描的间隔秒数（负载高时自动拉长） |
| `wan_dev` | auto | WAN 设备或逻辑接口，空格分隔 |
| `tooltips` | 1 | 维护 tooltip 数据（消耗 CPU） |
| `l2_overhead` | auto | 每包链路层开销字节数（`auto` 或 0-99） |
| `attr_*` | 见 LuCI | 把路由器代理流量归属到局域网设备；`attr_max_devices` 为设备表上限（默认 64） |
| `sock` | /var/run/netifyd/netifyd.sock | netifyd 套接字（必须是 /var/run/netifyd 下的 `.sock`） |
| `persist_dir` | 空 | 历史存储路径（/mnt、/media、/tmp/mnt 下），空 = 仅内存 |
| `persist_sec` | 3600 | 写盘间隔秒数（最小 60） |
| `persist_timeout` | 10 | 存储访问超时（3-120 秒） |
| `hist_sec`、`hist_keep`、`hist_hour_keep`、`hist_day_keep` | 300、288、744、400 | 历史分辨率与保留量 |
| `app_max`、`host_max`、`row_keep` | 400、200、40 | 表格条目上限 |
| `domain_auto_update`、`domain_update_days` | 1、7 | 服务库自动更新与间隔 |
| `domain_source` | auto | 服务库下载源：`auto`（GitHub + 镜像回退）、`github`、`ghfast`、`ghproxy`、`gh-proxy`、`moeyy`、`custom` |
| `domain_url` | 空 | `domain_source=custom` 时使用的目录 URL（存放 `dlc.dat_plain.yml` 与其 `.sha256sum`） |
| `alert_groups` | category-porn | 命中即标红的 v2fly 分组 |

分类器选项（供 `nss-ctstat.qos` 使用，修改后重启 SQM）：

| 选项 | 默认值 | 含义 |
|---|---|---|
| `bulk_bytes` | 314572800 | WEB/P2P/BE 流超过该字节数（300 MiB）转为 BULK |
| `reset_ct_marks` | 1 | SQM 启动时清零 conntrack 标记；与 mwan3 共用时设 0 |
| `dns_redirect` | 0 | 把所有非 WAN 接口的 DNS（53 端口）重定向到路由器 |
| `dns_redirect_exclude` | 空 | 不参与重定向的接口（如 `wg0`） |
| `ttl_fix` | 0 | 把 TTL / 跳数 63、127 改写为 64 |

## 服务库（V2Fly）更新

`设置 → 服务数据库 → 立即更新` 会下载
`https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat_plain.yml`
及其 `.sha256sum`，校验后编译成本地查询表。GitHub release 在部分网络下会“连上但零字节”，
表现为 `curl: (28) Operation timed out ... 0 bytes received`，因此更新器按以下顺序回退：

| 顺序 | 源 | 说明 |
|---|---|---|
| 1 | `github.com` | 官方 |
| 2 | `ghfast.top` | 公共加速 |
| 3 | `ghproxy.net` | 公共加速 |
| 4 | `gh-proxy.com` | 公共加速 |
| 5 | `github.moeyy.xyz` | 公共加速 |

每个镜像对每个下载器最多 25 秒；DNS 失败或连接被黑洞时直接换下一个镜像，不再让三个下载器各等一遍。
状态行会写明每个镜像的具体原因，例如
`下载失败：dlc.dat_plain.yml（github: 连接超时, ghfast: 域名解析失败）`。
若全部镜像均不可达，可在 `设置 → 下载源` 里选定一个可用镜像，或选择“自定义 URL”
填入内网镜像地址；本地 HTTP 也可以。

## nss-ctstat.qos

面向高通 NSS 硬件加速的 SQM 脚本（nsstbl + nssfq_codel），**只用 nftables**（`inet qos_custom` 表）。
在 SQM 页面选择队列算法 `fq_codel`、脚本 `nss-ctstat.qos`。只支持一个 SQM 实例
（共用 `nssifb` 和 nft 表），只使用数据包/conntrack 标记的低字节。

类别（标记低字节）：0x1 PRIO、0x2 VOIP、0x3 GAME、0x4 WEB、0x5 STREAM、0x6 BULK、0x7 P2P、0x8 BE、
0x9 VPN、0xa MAIL、0xb NTP、0xc FTP、0xd REMOTE、0xe DB、0xf MGMT、0x10 CONTAINER、0x11 IOT、
0x40 路由器自身流量。规则顺序即优先级。

从 `nss-rk.qos` / `nss-trafficchart.qos` 升级：postinst 会运行 `ctstat-migrate`，把 `/etc/config/sqm`
里的旧脚本名改为 `nss-ctstat.qos` 并删除旧文件；SQM 不会自动重启（重启 nssifb 可能导致路由器崩溃），
请自行执行 `/etc/init.d/sqm restart`。

## 排障

- 提示聚合进程未运行 / 数据过期：`/etc/init.d/ctstat restart`，然后 `logread | grep ctstat`。
- 没有应用名：检查 `socat`、`netifyd` 以及 `/etc/netifyd.conf` 里的 `listen_path`。
- “未归属”流量：整形器实际承载但 conntrack 未统计的部分（路由器自身服务、组播、被丢弃的入站包），
  链路层开销会自动测量（`l2_overhead`）。
- 服务库更新失败：在 `设置 → 下载源` 换一个镜像；状态行会给出每个镜像的失败原因。日志见
  `/var/run/ctstat/domains-update.log`。
- 规则检查：`nft list table inet qos_custom`；生成的文件在 `/tmp/nss-ctstat-qos.nft`，
  可用 `nft -c -f` 校验。
- 确认是 fw4：`fw4 print` 正常输出、`/sbin/fw4` 存在。若系统只有 fw3，本包不会工作。

## 工作原理（简版）

硬件加速（flow offload / NSS PPE）会让已建立的连接绕过内核转发路径，因此不能靠统计经过
iptables/nftables 的包来画应用流量图。本项目改用 **conntrack 记账**：

```
内核连接跟踪（nf_conntrack_acct=1）
        │  每连接的 bytes / packets
        ▼
ctstat-agg（周期性读取 /proc/net/nf_conntrack，只累加增量）
        │
        ├── 应用 / 设备 / 目标聚合
        └── 写入 /var/run/ctstat/classes.json + history*.json
                     │
                     ▼
              LuCI 页面（rpcd 只读转发，不做计算）
```

链路总速率来自 `tc` qdisc 计数器，与 conntrack 的差值（扣除链路层开销）显示为“未归属”，
因此硬件加速开启时仍能同时看到真实链路速率和按应用的分布。

## 校验

发布前执行：所有脚本 `sh -n`、awk 程序可解析、JSON 合法、LuCI JS `node --check`、生成的 nft 规则集
通过 `nft -c`（默认 / PPPoE / FTP helper / DNS 重定向 / TTL 改写）、`.lmo` 翻译目录可用。

## 许可与来源

GPL-2.0-or-later，见 [LICENSE](LICENSE)。原始作者 m0g13r，本 fork 由 YunHair 维护。
