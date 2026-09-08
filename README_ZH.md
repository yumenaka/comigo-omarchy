# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

[Comigo](https://github.com/yumenaka/comigo) 漫画与图片阅读器的 Omarchy 状态栏插件，支持中文、英文和日文。

## 安装插件

需要支持 Shell 插件的 Omarchy、Bash 和 curl。Comigo 服务端要求 **v1.3.5 或以上**。

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

安装后，点击状态栏中的 Comigo 图标打开面板。

## 使用方法

### 本机模式（默认）

1. 打开“服务”选项卡，点击“安装 Comigo 二进制文件”，按提示完成安装。已经安装的用户可跳过此步。
2. 安装完成后点击“启动”，启动 Comigo。
3. 在“概览”中打开阅读链接，或扫描二维码阅读。

需要指定书库时，在“设置”中填写书库目录并保存；留空则使用 Comigo 的默认规则。希望登录桌面后自动启动，可在“服务”中开启自动启动。

### 远程模式

1. 在侧栏切换到“远程”模式。
2. 在“设置”中输入远程 Comigo 的完整链接，例如 `https://reader.example/books/`，然后点击“保存”。
3. 如果服务要求认证，先登录，再从“概览”打开阅读链接或扫描二维码。

远程 Comigo 需要已启动；本机无需安装 Comigo 二进制文件。切换模式不会启停服务。

## 其他功能

- **状态**：查看版本、书籍与连接数量，以及收发速度和累计流量。
- **局域网阅读**：本机在“设置”中开启对外服务后，可在“概览”切换可用 IP；必要时通过防火墙按钮放行端口。
- **服务管理**：停止、重启、查看日志和检查更新。插件只能控制自己启动的进程，更新检查不会自动升级。
- **语言与快捷键**：侧栏可切换语言；`1`–`4` 切换页面，`r` 刷新，`Esc` 关闭面板。

关闭面板不会停止 Comigo。连接失败时，检查服务是否运行、链接是否正确，并查看“服务”中的日志。

## 卸载

```bash
omarchy plugin remove yumenaka.comigo
```

卸载保留设置与书库，也不会停止服务；如需停止，请先在插件中操作。

## 开发

源码安装或更新使用 `bash install.sh`，会重启 Omarchy Shell；源码安装的副本使用 `bash install.sh --uninstall` 卸载。开发约定与验证命令见 [AGENTS.md](AGENTS.md)，详细说明见 Comigo 内置的 `/manual/comigo-omarchy` 手册。

## 许可与致谢

采用 MIT 许可，见 [LICENSE](LICENSE)。界面模仿了 [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin)。
