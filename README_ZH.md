# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

[Comigo](https://github.com/yumenaka/comigo) 漫画与图片阅读器的 Omarchy 状态栏控制面板。在桌面上打开阅读链接与二维码、查看服务状态，并管理本机 Comigo CLI。界面支持中文、英文和日文。

## 安装

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

插件 ID 为 `yumenaka.comigo`。点击状态栏图标打开面板。本机找不到 CLI 时进入“服务”页，可通过安装按钮下载 comigo.xyz 上对应平台的 `comi` 发布包。PATH 包含 `/usr/bin` 时默认安装到 `/usr/bin/comi`，否则为 `~/.local/bin/comi`。写入系统目录需要管理员认证，已有目标不会被覆盖。

## 卸载

```bash
omarchy plugin remove yumenaka.comigo
```

源码安装的副本，在对应源码目录运行 `bash install.sh --uninstall`。卸载保留设置与书库，也不会停止 Comigo；如果不希望服务继续运行，请先在插件中停止它。

## 依赖

需要支持 Shell 插件的 Omarchy、Bash 和 curl。界面与文件操作使用 Quickshell 及宿主基础工具。服务端要求 **Comigo v1.3.5 或以上**；本机模式还需要 Comigo CLI，远程模式不要求本机安装 CLI。

## 页面

| 页面 | 功能 |
| --- | --- |
| 概览 | 打开或复制阅读地址、显示二维码、切换本机 IP |
| 状态 | 查看服务状态、版本、书籍和连接数、收发速度与累计流量 |
| 服务 | 本机服务启停与重启、自动启动、日志、CLI 安装、更新检查 |
| 设置 | 本机与远程连接、书库与 CLI 路径、登录、对外服务、防火墙，以及实际配置文件信息 |

## 语言

界面默认跟随系统语言，未支持的语言回退到英文。使用侧栏的 EN / 中文 / 日本語 按钮切换语言；选择保存在 `settings.json` 中，Shell 重启后仍然生效。

## 连接本机书库

1. 在侧栏选择“本机”，进入“设置”。
2. 填写服务的回环地址，通常为 `http://127.0.0.1:1234/`。协议、端口及 BasePath 必须与服务一致，例如 `http://127.0.0.1:1234/books/`。
3. CLI 路径留空时从 PATH 查找 `comi` 或 `comigo`，也可填写完整路径。书库目录留空时由 Comigo 自行决定默认书库；指定目录时，该目录必须存在。
4. 保存后进入“服务”页启动 Comigo。如果服务要求认证，在“设置”页登录。

连接地址只决定面板连接到哪里，不会修改服务的端口、TLS 或 BasePath。插件执行 `comi --no-tui --open-browser=false`，仅在指定书库时传入书库参数，并以该目录作为工作目录；留空时沿用启动目录。配置由 Comigo 自动查找和加载。配置文件区域显示实际路径、保存位置、运行类型、格式与存在状态，管理按钮进入网页设置。

插件只能停止自己启动并记录的进程；端口被占用时拒绝启动。如要接管通过其他方式启动的服务，先通过原启动方式停止它。关闭面板不会停止 Comigo。

## 阅读与切换 IP

概览默认使用服务返回的阅读地址，通常为出口网卡 IP。本机启用对外服务且存在多个 IP 时，二维码两侧箭头循环切换地址。阅读链接、二维码和打开／复制操作随选择同步，当前 IP 加粗显示。支持 IPv6，并保留协议、端口和 URL 路径。轮询期间保留仍然可用的选择；仅本机监听时不提供 IP 切换。

其他设备阅读前，需要启用对外服务，并确保能够访问所选地址。“设置”中的对外服务开关会改变 Comigo 的监听范围，随后等待服务重连。只读服务不允许修改此项。

已安装并启用 UFW 时，防火墙按钮可放行默认网卡直连私有 IPv4 网段到当前 TCP 端口，操作需要管理员认证。撤销只移除带 `omarchy-comigo` 标记的规则，保留用户自己的规则。规则已配置不代表能穿透其他网络限制。

## 连接远程服务

选择“远程”，在设置中填写服务的完整 HTTP(S) 主页地址并保存。地址应包含 BasePath，例如 `https://reader.example/books/`。远端服务必须已启动且可访问；要求认证时登录。

四个页面均使用远程数据。阅读链接和二维码使用配置的远程地址，不提供本机 IP 切换。本机安装、进程控制、日志、CLI／书库路径、对外服务和防火墙操作隐藏。本机与远程分别保存 URL 和认证会话；切换模式不会启停任何服务，Shell 启动时默认本机模式。

## 快捷键

`1`–`4` 选择页面，左右方向键切换页面，上下方向键滚动，`r` 刷新，Esc 关闭。输入框保持正常文字编辑按键。

## 说明

自动启动默认关闭。在“服务”页开启后，插件会在桌面会话中加载时尝试启动本机 CLI，当前会话也会开始尝试，不使用 systemd。失败后间隔至少 10 秒，每次登录最多尝试三次。重载插件或 Shell 不重置次数；成功或手动控制进程后结束当前会话的自动尝试。关闭开关取消后续重试；达到上限后可手动启动。

更新检查显示结果、发布页面和可复制的 CLI 升级命令，不执行安装。已连接的服务通过 API 检查；本机服务停止时使用 `comi desktop check-update`。升级二进制后需重启 Comigo。`comi desktop info` 在不启动服务的情况下返回桌面协议 `1`。

- 设置：`${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-comigo/settings.json`。
- 日志：`${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-comigo/comi.log`。
- 进程和自动启动记录：正常桌面会话中的 `$XDG_RUNTIME_DIR/omarchy-comigo/`。

设置不保存密码或令牌。认证会话按模式与 URL 隔离，仅保留在内存中；密码提交后清空。Shell 重启或令牌过期后需要重新登录。外部修改设置时，未编辑字段自动同步，草稿保留。完整状态约每 30 秒刷新；面板打开时每两秒刷新流量，设置页按此间隔刷新运行配置。流量只统计当前 Comigo 进程的 HTTP 正文，不是整机网络流量；进程重启后归零。

## 排障

- **版本或接口不支持**：使用 Comigo v1.3.5 或以上，本机桌面能力可用 `comi desktop info` 检查。
- **离线或启动超时**：核对连接地址与服务实际配置，并查看服务日志；填写 URL 不会修改服务配置。
- **没有 IP 箭头**：确认本机模式、对外服务已开启且有多个可用 IP。
- **匿名连接的登录控件不可用**：服务要求认证或已有登录会话时才启用。
- **面板未显示安装的代码**：运行 `omarchy restart shell` 后重新打开。

## 开发

从源码安装：

```bash
git clone https://github.com/yumenaka/comigo-omarchy.git
cd comigo-omarchy
bash install.sh
```

脚本校验、复制插件，重启 Omarchy Shell 并启用插件。再次执行即可同步源码。Shell 重启会关闭弹窗并清空插件登录会话，已运行的 Comigo 服务继续运行。

```bash
omarchy plugin validate .
for script in install.sh bin/* tests/*.sh; do
  bash -n "$script" || exit 1
done
for test in tests/test-{ctl,refresh,modes,reading-ip,version,autostart,firewall}.sh; do
  bash "$test" || exit 1
done
COMIGO_TEST_CLI=/path/to/comi bash tests/test-default-library.sh
COMIGO_TEST_CLI=/path/to/comi bash tests/smoke.sh
```

QML 测试需要 Wayland 会话；联调测试使用隔离服务。参见[开发约定](AGENTS.md)、[Comigo 中文文档](https://github.com/yumenaka/comigo/blob/master/README_ZH.md)，以及 Comigo 服务内置的 `/manual/comigo-omarchy` 手册。

## 许可与致谢

采用 MIT 许可，见 [LICENSE](LICENSE)。界面模仿了 [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin)。
