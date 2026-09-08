# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

An Omarchy status bar plugin for the [Comigo](https://github.com/yumenaka/comigo) comic and image reader, with English, Chinese, and Japanese support.

## Install the plugin

Requires Omarchy with shell plugin support, Bash, and curl. The Comigo server must be **v1.3.5 or later**.

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

After installation, click the Comigo icon in the status bar to open the panel.

## Usage

### Local mode (default)

1. Open the **Service** tab, click **Install Comigo binary**, and follow the prompts. Skip this step if Comigo is already installed.
2. Click **Start** to start Comigo.
3. Open the reading link or scan the QR code on **Overview**.

To choose a library, enter its directory in **Settings** and save; leave it empty to use Comigo's defaults. Enable automatic startup on **Service** to start Comigo when you log in to the desktop.

### Remote mode

1. Switch to **Remote** in the sidebar.
2. Enter the remote Comigo server's full URL in **Settings**, such as `https://reader.example/books/`, and click **Save**.
3. Log in if the server requires authentication, then open the reading link or scan the QR code on **Overview**.

The remote Comigo server must already be running. No local Comigo binary is needed. Switching modes does not start or stop a service.

## Other features

- **Status:** view the version, book and connection counts, transfer rates, and totals.
- **LAN reading:** enable external access in local **Settings**, then select an available IP on **Overview**. Use the firewall buttons to allow the port if needed.
- **Service management:** stop, restart, view logs, and check updates. The plugin only controls processes it started; update checks do not install updates.
- **Language and shortcuts:** select a language in the sidebar; use `1`–`4` to switch pages, `r` to refresh, and `Esc` to close the panel.

Closing the panel does not stop Comigo. If a connection fails, check that the service is running, verify its URL, and inspect the logs on **Service**.

## Remove

```bash
omarchy plugin remove yumenaka.comigo
```

Removal preserves settings and books and does not stop the service. Stop it through the plugin first if needed.

## Development

Use `bash install.sh` to install or update from a source checkout; this restarts Omarchy Shell. Remove a source-installed copy with `bash install.sh --uninstall`. See [AGENTS.md](AGENTS.md) for development and validation commands, and Comigo's built-in `/manual/en-US/comigo-omarchy` manual for details.

## License and acknowledgments

MIT licensed; see [LICENSE](LICENSE). The interface is inspired by [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin).
