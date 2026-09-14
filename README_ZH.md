<div align="center">

# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

</div>

![Comigo Omarchy 插件预览](https://www.yumenaka.net/wp-content/uploads/2026/09/screenshot-comigo-omarchy-plugin.png)

[Comigo](https://github.com/yumenaka/comigo) 漫画与图片阅读器的 Omarchy 状态栏插件，支持中文、英文和日文。

## 安装插件

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

安装后，点击状态栏中的 Comigo 图标打开面板。

## 卸载

```bash
omarchy plugin remove yumenaka.comigo
```

## 使用与依赖

需要支持 Shell 插件的 Omarchy、curl 8.4 或以上版本，以及已运行的 Comigo v1.3.7 或以上版本（须提供 `/api/info` 接口）。插件通过 curl 调用 REST，本机无需安装 `comi`。请求不跟随 HTTP 重定向，请填写最终服务地址（含完整 BasePath）；每次请求超时 15 秒、响应上限 1 MiB。密码和令牌通过标准输入传递，不写入进程参数或临时文件。

1. 在插件外安装并启动 Comigo：[GitHub](https://github.com/yumenaka/comigo) 或 [comigo.xyz](https://comigo.xyz/)（中国大陆推荐）。
2. 在“设置”填写完整服务地址，例如 `http://127.0.0.1:1234/` 或 `https://reader.example/books/`。
3. 如果服务设置了密码，在插件内登录，再从“概览”打开阅读链接或扫描二维码。登录令牌只保存在内存中，按服务地址隔离。

服务连接失败时，打开面板默认进入设置页。插件设置由 Omarchy 宿主保存。

## 功能

- 四页：概览、状态、服务、设置。支持阅读链接、二维码、服务器 IP 切换、版本、书籍与连接数量、速度和累计流量。
- 仅当已保存的连接地址主机为 `127.0.0.1` 或 `localhost` 时显示对外服务开关，避免远程关闭后无法恢复；只读模式禁止修改服务设置。配置文件信息只读展示，详细配置进入 Comigo 网页。
- “服务”页提供 GitHub 和 comigo.xyz（中国大陆推荐）链接。插件不安装二进制、不启停 Comigo 进程、不操作 systemd 或防火墙，不提供更新检查。
- 开机启动在 Comigo 网页设置的“服务控制”或 CLI 中管理，默认关闭；Linux 下使用 systemd 用户服务，于用户登录后启动。停止的服务需在插件外启动。
- 侧栏可切换中英日语言；`1`–`4` 切换页面，`r` 刷新，`Esc` 关闭。

关闭或卸载插件不会停止 Comigo，也不会删除书库。连接失败时检查服务运行状态、完整地址与认证信息。

## 使用手册

详细说明见 [Comigo 手册](https://comigo.xyz/manual/comigo-omarchy)。

## 许可与致谢

采用 MIT 许可，见 [LICENSE](LICENSE)。界面模仿了 [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin)。
