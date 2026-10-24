# 开发规则

- 开发基线始终跟随 Omarchy 官方最新开发分支（当前为 `quattro`），每次开发先在线核对最新提交及 [Shell reference](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)、[开发指南](https://plugins.omarchy.org/develop.html)与[发布指南](https://plugins.omarchy.org/publish.html)。不以本机版本代替最新规范，不增加旧接口兼容层；插件自身版本号独立维护。
- 当前最低 Comigo 版本为 v1.3.10；版本门槛、三语界面提示与 README 必须同步，配套 Comigo 内置手册也须同步。
- 配置使用宿主提供的条目及 `shell.updateEntryInline`，生命周期使用宿主接口；调色板使用 `Commons.Color`。不得绕过宿主能力边界读取其他插件或认证服务。
- REST 与二维码共用受限 curl 通道：忽略 curlrc、不跟随重定向、仅 HTTP(S)、15 秒超时、1 MiB 上限。凭据仅经标准输入传递，令牌仅保留内存。
- 不添加安装、后台管理或临时测试脚本；临时验收放系统临时目录。保留 LICENSE 和第三方许可说明。
- 修改后执行 `omarchy plugin validate`、使用宿主导入路径的 `qmllint`，验证认证、重定向、超时、大小限制、地址切换与退出取消、界面及版本边界。本机部署保留安装目录 `.git`，同步插件拥有的文件并重启 Shell 验证；提交与推送需用户授权。
