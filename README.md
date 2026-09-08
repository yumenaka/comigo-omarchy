# comigo-omarchy

Comigo 的原生 Omarchy 状态栏控制面板。界面参考 [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin)：固定大小弹窗、左侧导航、右侧卡片、侧栏语言切换和实时速度。

| 页面 | 功能 |
| --- | --- |
| 概览（默认） | 二维码、下方阅读地址与打开/复制按钮、服务器 IP |
| 状态 | 服务状态、版本、收发速度、累计流量、书籍与连接统计 |
| 服务 | 控制、开机启动选项、日志、下载安装 CLI、更新检查及升级命令 |
| 设置 | 连接地址、CLI、书库、实际配置文件信息、登录会话 |

## 依赖与安装

额外运行依赖只有 **Bash 和 curl**。Omarchy/Quickshell、系统自带的 tar 与基本文件工具是宿主设施。剪贴板和浏览器调用使用 Quickshell 自带能力。

在独立插件仓库执行：

```bash
bash install.sh
```

脚本校验、复制并重启 Omarchy Shell 后启用插件，确保加载最新 QML 组件。修改源码后重新执行即可同步；重启会关闭 Shell 弹窗并清空插件内存中的登录会话，Comigo 服务继续运行。也可从 GitHub 安装：

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

本机模式需要 Comigo CLI；远程模式不需要本机安装 CLI。未安装时默认进入“服务”页，提供“安装 Comigo 二进制文件”按钮：从 comigo.xyz 下载本平台架构的发布包，只提取并验证 comi，不运行远程脚本。PATH 包含 `/usr/bin` 时安装到 `/usr/bin/comi`，系统认证对话框授权最后的复制操作；否则安装到 `~/.local/bin/comi`。已有目标不会被覆盖。安装成功后自动保存 CLI 路径。页面也保留安装脚本和官网的打开/复制按钮。最低支持 Comigo v1.3.5；`comi desktop info` 返回的 `desktopProtocol` 应为 `1`。版本不符合要求或缺少接口时提示升级。

## 配置和启动

侧栏语言按钮上方可切换“本机 / 远程”，Shell 启动时默认本机。切换只改变面板连接，不会启停本机服务。

本机与远程地址分别保存。远程模式各页显示远程的版本、书籍、连接、IP、流量和配置文件信息；服务页提供连接状态与更新检查。远程模式隐藏本地启停、安装、日志、升级命令、CLI/书库设置、对外服务开关及防火墙。未配置远程地址时自动进入设置页；填写包含 BasePath 的完整 URL 后保存即可连接。阅读、复制及二维码使用该远程 URL。

本机启用对外服务且有多个 IP 时，可用二维码两侧的 ◀ / ▶ 循环切换阅读地址和二维码，列表中的当前 IP 加粗显示。默认使用服务返回的出口 IP；切换保留协议、端口和路径。

本机模式在“设置”页填写并保存：

- **连接地址**：仅接受本机回环地址，默认 `http://127.0.0.1:1234/`，有 BasePath 时包含前缀。必须与 Comigo 的实际协议、端口和路径一致。
- **CLI 路径**：留空依次探测 `comi`、`comigo`；也可填写 CLI 的完整路径。
- **书库目录**：留空时由 Comigo 自身的默认规则处理；指定时目录必须已存在。
- **配置文件**：只读显示 Comigo 实际文件的路径、保存位置、运行类型和存在状态；管理按钮进入网页的配置文件管理模块。

保存后在“服务”页启动。插件使用 `nohup comi --no-tui --open-browser=false` 直接运行二进制文件。指定书库时以该目录作为工作目录；书库留空时沿用启动目录。配置文件由 Comigo 自动查找和解析。

服务页的“开机启动 Comigo 服务”默认关闭，保存为 `autoStart`。开启后，登录桌面加载插件时自动调用本地 `comi`，无需 systemd；当前会话开启选项也会开始尝试。只在本机模式执行，失败后间隔 10 秒重试，最多尝试 3 次。次数和完成标记保存在用户运行目录，插件或 Shell 重载不重置预算；运行目录在退出登录或重启后清空。成功、已运行或手动启停后结束自动启动，本次登录不会自动拉起手动停止的服务；关闭选项取消后续重试。达到上限后可在服务页手动启动。

只有本插件启动并记录 PID 与内核启动时间的进程可被停止、重启。过期记录不会导致误杀其他进程；端口已占用时拒绝启动。启动后等待健康检查，超时会停止本次进程。关闭面板或重载 Shell 不会停止 Comigo。日志位于 `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-comigo/comi.log`，运行记录位于 `$XDG_RUNTIME_DIR/omarchy-comigo/`。

设置保存在 `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-comigo/settings.json`，只含非敏感设置。文件外部修改会自动同步；设置页每两秒读取运行配置，未保存草稿会保留。后台查询不会禁用按钮，数据未变化时复用界面快照。中、英、日语言可在侧栏切换。密码提交后立即清空，Bearer 会话按模式和连接地址分别保存在内存，切换恢复各自会话，退出只清除当前会话；令牌经 stdin 传给 curl，不进入命令行、配置文件或日志。Shell 重启或令牌失效后重新登录。

设置页的“对外服务”开关控制 `127.0.0.1`（仅本机）或 `0.0.0.0`（局域网）。通过已认证的 `PATCH /api/configs` 更新 `DisableLAN`，Comigo 保存配置并重启 HTTP 监听，插件随后重连。只读模式下不可修改。

本机 UFW 防火墙可在设置页放行局域网端口：规则限制为默认网卡上的直连私有 IPv4 网段及当前端口，系统弹出管理员认证。更换网络或端口后可重新放行；“撤销本插件放行”删除带 `omarchy-comigo` 标记的全部规则，保留已有用户规则。UFW 与 ip 使用宿主工具；未安装或未启用 UFW 时不修改防火墙。规则已配置表示 UFW 配置状态，实际设备连通性还取决于网络隔离及其他规则。

## 核心接口

| 接口 | 用途 |
| --- | --- |
| `GET /api/server` | 完整状态、地址、累计流量及 `externalAccess` / `listenAddress`；约 30 秒刷新或手动刷新 |
| `GET /api/server/traffic` | 轻量流量快照；面板打开时每 2 秒刷新 |
| `GET /api/server/update` | 手动检查更新，服务端缓存一小时 |
| `GET /api/configs` | 不含密码的运行配置摘要 |
| `GET /api/configs/status` | `current` 返回实际文件的 `path`、`location`、`type`、`format`、`exists` |
| `POST /api/login` | JSON 登录，签发 Bearer token |
| `GET /api/qrcode.png` | 根据阅读地址生成二维码 |
| `comi desktop info` | 不启动服务的 JSON 能力探测 |
| `comi desktop check-update` | 服务停止时检查更新，复用核心版本比较 |

配置位置 `location` 与网页一致：`HomeDirectory`、`WorkingDirectory`、`ProgramDirectory`，并区分自定义路径 `Custom` 和仅内存 `None`。运行类型 `type` 为 `cli`、`desktop` 或 `tray`，文件格式为 `toml`。文件删除后 `exists` 为 false，内存中的已加载配置继续生效。

所有受保护 REST 接口沿用 Comigo 登录认证和 BasePath。插件不绕过登录，不通过 REST 创建或启动本机服务。

流量统计包括本进程实际读写的 HTTP 正文，发送量含 gzip 压缩效果；不含协议头、TLS/TCP、WebSocket 帧及服务访问远端书库的出站请求。进程重启清零，速度是最近五秒平均值。状态轮询自身也计入流量。缺少接口显示“不支持”，不伪造为零。

更新检查只显示版本、发布页和可复制升级命令，不下载或执行升级。升级 CLI 后需重启服务才能使用新版本。

## 键盘与开发

`1`–`4` 切换页面，左右键切换页面，上下键滚动，`r` 刷新，`Esc` 关闭。输入框获得焦点时使用正常文字输入。

```bash
omarchy plugin validate .
bash -n install.sh bin/* tests/*.sh
bash tests/test-ctl.sh
bash tests/test-refresh.sh
bash tests/test-modes.sh
bash tests/test-reading-ip.sh
bash tests/test-version.sh
bash tests/test-autostart.sh
bash tests/test-firewall.sh
# 需要 Wayland 会话及 Comigo 可执行文件；测试使用隔离服务。
COMIGO_TEST_CLI=/path/to/comi bash tests/test-default-library.sh
COMIGO_TEST_CLI=/path/to/comi bash tests/smoke.sh
```

Go 后端测试在 Comigo 源码仓库运行。约定见 [AGENTS.md](AGENTS.md)，参考组件归属见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 卸载

```bash
bash install.sh --uninstall
```

只删除本脚本拥有的安装副本，保留服务和书库。远程仓库安装的副本使用 `omarchy plugin remove yumenaka.comigo`。

如不再需要后台进程，卸载前在“服务”页点击停止。书库与设置不会被删除。
