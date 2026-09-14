<div align="center">

# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

</div>

![Comigo Omarchy plugin preview](https://www.yumenaka.net/wp-content/uploads/2026/09/screenshot-comigo-omarchy-plugin.png)

An Omarchy status bar plugin for the [Comigo](https://github.com/yumenaka/comigo) comic and image reader, with English, Chinese, and Japanese support.

## Install the plugin

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

After installation, click the Comigo icon in the status bar to open the panel.

## Remove

```bash
omarchy plugin remove yumenaka.comigo
```

## Usage and requirements

Requires Omarchy with Shell plugin support, curl 8.4 or later, and a running Comigo v1.3.7 or later with the `/api/info` endpoint. The plugin calls REST through curl; no local `comi` binary is required. Requests do not follow HTTP redirects: enter the final service URL, including its BasePath. Each request has a 15-second timeout and a 1 MiB response limit. Passwords and tokens pass through standard input, never command arguments or temporary files.

1. Install and start Comigo outside the plugin: [GitHub](https://github.com/yumenaka/comigo) or [comigo.xyz](https://comigo.xyz/) (recommended for mainland China).
2. Enter the full service URL in Settings, such as `http://127.0.0.1:1234/` or `https://reader.example/books/`.
3. If password protection is enabled, sign in within the plugin, then open the reading link or scan the QR code. Tokens stay in memory and are isolated by service URL.

When the service is unavailable, opening the panel defaults to Settings. Plugin settings are saved by the Omarchy host.

## Features

- Four pages: Overview, Status, Service and Settings. Reading links, QR codes, server IP selection, version, book and connection counts, transfer rates and totals.
- The external access switch is shown only when the saved service URL host is `127.0.0.1` or `localhost`, to avoid losing remote access with no way to restore it. Read-only mode blocks service setting changes. Configuration file information is read-only; use the Comigo website for detailed settings.
- The Service page links to GitHub and comigo.xyz (recommended for mainland China). The plugin does not install binaries, manage Comigo processes, systemd or firewall rules, or check for updates.
- Configure startup in Server control in Comigo's web settings or CLI. It defaults to off and uses a systemd user service on Linux, starting after user login. Start a stopped service outside the plugin.
- Switch between English, Chinese and Japanese in the sidebar; `1`–`4` select pages, `r` refreshes, and `Esc` closes the panel.

Closing or removing the plugin does not stop Comigo or delete libraries. If connection fails, check that the service is running and verify its full URL and credentials.

## Manual

See the [Comigo manual](https://comigo.xyz/manual/comigo-omarchy) for details.

## License and acknowledgments

MIT licensed; see [LICENSE](LICENSE). The interface is inspired by [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin).
