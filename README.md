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

Removal preserves settings and books and does not stop the service. Stop it through the plugin first if needed.

## Dependencies

- **Plugin:** Omarchy with shell plugin support, `bash`, and `curl`.
- **Comigo:** local mode requires the `comi` binary **v1.3.6 or later**; if missing, **Service** links to the [GitHub project](https://github.com/yumenaka/comigo) and [comigo.xyz](https://comigo.xyz/) (recommended in mainland China). Install Comigo separately; the plugin does not download or install binaries. Remote mode requires a running server of the same minimum version, with no local binary needed.
- **Optional features:** firewall controls use `ufw`, `ip`, and `pkexec`.

## Usage

### Local mode (default)

1. If Comigo is missing, follow a source linked in **Service** to install it separately. Existing installations are detected automatically; if detection fails, set the binary path in **Settings**.
2. After installation, refresh the panel and click **Start**.
3. If authentication is required, log in through **Settings**. Then open the reading link or scan the QR code on **Overview**.

To choose a library, enter its directory in **Settings**, save, and restart the local service; leave it empty to use Comigo's defaults. Enable automatic startup on **Service** to start Comigo when you log in to the desktop.

### Remote mode

1. Switch to **Remote** in the sidebar.
2. Enter the remote Comigo server's full URL in **Settings**, such as `https://reader.example/books/`, and click **Save**.
3. Log in if the server requires authentication, then open the reading link or scan the QR code on **Overview**.

Switching modes does not start or stop a service.

## Other features

- **Status:** view the version, book and connection counts, transfer rates, and totals.
- **LAN reading:** enable external access in local **Settings**, then select an available IP on **Overview**. Use the firewall buttons to allow the port if needed.
- **Service management:** stop, restart, and view logs in local mode. The plugin only controls processes it started. The Service page provides GitHub and comigo.xyz (recommended in mainland China) links in both modes.
- **Language and shortcuts:** select a language in the sidebar; use `1`–`4` to switch pages, `r` to refresh, and `Esc` to close the panel.

Closing the panel does not stop Comigo. If a connection fails, check that the service is running, verify its URL, and, in local mode, inspect the logs on **Service**.

## Development

Use `bash install.sh` to install or update from a source checkout; this restarts Omarchy Shell. Remove a source-installed copy with `bash install.sh --uninstall`. See Comigo's built-in `/manual/en-US/comigo-omarchy` manual for details.

## License and acknowledgments

MIT licensed; see [LICENSE](LICENSE). The interface is inspired by [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin).
