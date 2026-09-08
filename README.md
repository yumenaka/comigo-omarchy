# comigo-omarchy

[English](README.md) | [中文](README_ZH.md) | [日本語](README_JP.md)

An Omarchy status bar panel for [Comigo](https://github.com/yumenaka/comigo), the comic and image reader. Open reading links and QR codes, monitor a server, and manage a local Comigo CLI from the desktop. The panel supports English, Chinese, and Japanese.

## Install

```bash
omarchy plugin add https://github.com/yumenaka/comigo-omarchy --enable
```

The plugin ID is `yumenaka.comigo`. Open its icon in the status bar. If no CLI is found, local mode opens the Service page, where the install button downloads the platform's `comi` release from comigo.xyz. The default target is `/usr/bin/comi` when `/usr/bin` is on PATH, otherwise `~/.local/bin/comi`. Writing to the system directory requests administrator authentication; an existing target is not overwritten.

## Remove

```bash
omarchy plugin remove yumenaka.comigo
```

For a copy installed from a local checkout, run `bash install.sh --uninstall` from that checkout. Removal preserves settings and books and does not stop Comigo; stop a plugin-managed service first if it should not remain running.

## Dependencies

Requires Omarchy with shell plugin support, Bash, and curl. Quickshell and standard host tools provide the UI and file operations. Comigo **v1.3.5 or later** is required on the server. Local mode also requires the Comigo CLI; remote mode does not require a local CLI.

## Pages

| Page | What you can do |
| --- | --- |
| Overview | Open or copy the reading URL, scan its QR code, and select a local IP |
| Status | View service status, version, book and connection counts, transfer rates, and totals |
| Service | Start, stop, or restart a local service; configure automatic startup; view logs; install the CLI; check updates |
| Settings | Configure local or remote connections, library and CLI paths, login, LAN access, and firewall rules; inspect the active config file |

## Language

The UI follows the system language by default, with English as the fallback. Use the EN / 中文 / 日本語 buttons in the sidebar to choose a language. The choice is saved in `settings.json` and survives Shell restarts.

## Connect to a local library

1. Select **Local** in the sidebar and open **Settings**.
2. Set the connection URL to the service's loopback address, normally `http://127.0.0.1:1234/`. Match its protocol, port, and any BasePath, for example `http://127.0.0.1:1234/books/`.
3. Leave the CLI path empty to find `comi` or `comigo` on PATH, or supply its full path. Leave the library directory empty to use Comigo's own defaults, or choose an existing directory.
4. Save, then open **Service** and start Comigo. If the server requests authentication, log in on **Settings**.

The connection URL tells the panel where to connect; it does not change the server's port, TLS, or BasePath. The plugin runs `comi --no-tui --open-browser=false` and supplies a library path only when configured. An explicit library directory is also the working directory; otherwise the process inherits the launch directory. Comigo locates and loads its configuration. The config file section displays its path, location, profile, format, and existence; its management button opens the Web settings page.

Only a process started and recorded by the plugin can be stopped. A port already in use prevents startup. To use the plugin's process controls for a separately launched service, stop that service through its owner first. Closing the panel does not stop Comigo.

## Read and switch IPs

Overview defaults to the server's reading URL, normally its outbound interface IP. With external access enabled and multiple local IPs available, the arrows beside the QR code cycle through addresses. The reading URL, QR code, and open/copy actions follow the selection; the matching IP is bold. IPv6, the protocol, port, and URL path are preserved. Polling retains the selection while the address remains available. Local-only mode has no IP switching.

For another device to read, enable external access and make sure that device can reach the selected address. In **Settings**, the LAN switch changes Comigo's listener and waits for it to reconnect. Read-only servers do not permit this change.

If UFW is installed and enabled, the firewall buttons can allow the current TCP port from the default interface's directly connected private IPv4 subnet. The operation requests administrator authentication. Revoking access removes only rules marked `omarchy-comigo`, leaving user-owned rules intact. A configured rule does not guarantee reachability through other network restrictions.

## Connect to a remote server

Select **Remote**, enter the server's full HTTP(S) home URL in Settings, and save. Include its BasePath, for example `https://reader.example/books/`. The remote server must already be running and reachable. Log in if requested.

All four pages use remote data. Reading links and QR codes keep the configured remote URL; local IP cycling is unavailable. Local installation, process controls, logs, CLI/library settings, LAN toggles, and firewall actions are hidden. Local and remote URLs and authentication sessions are separate. Switching mode does not start or stop either server; Shell startup defaults to Local.

## Keyboard

`1`–`4` select pages, Left/Right switch pages, Up/Down scroll, `r` refreshes, and Esc closes the panel. Text fields keep their normal editing keys.

## Notes

Automatic startup is off by default. Enable it on Service to let the plugin start the local CLI when loaded in your desktop session, including the current session. It uses no systemd service. Failed attempts are spaced by at least 10 seconds, with at most three per login session. Reloading the plugin or Shell does not reset that budget. Success or manual process control ends automatic attempts for that session; disabling the option cancels further retries. Use Start manually after the limit is reached.

Update checks display the result, release page, and a copyable CLI upgrade command. They do not install updates. A running server is checked through its API; a stopped local service uses `comi desktop check-update`. Restart Comigo after upgrading its binary. `comi desktop info` reports desktop protocol `1` without starting a server.

- Settings: `${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-comigo/settings.json`.
- Logs: `${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-comigo/comi.log`.
- Process and automatic-start records: `$XDG_RUNTIME_DIR/omarchy-comigo/` in a normal desktop session.

Passwords and tokens are not saved in these settings. Sessions stay in memory and are separated by mode and URL; passwords are cleared after submission. Log in again after a Shell restart or token expiry. External settings changes update unedited fields while retaining drafts. Complete status refreshes about every 30 seconds; an open panel refreshes traffic every two seconds, and Settings refreshes running configuration at that interval. Traffic counts HTTP bodies for the current Comigo process, not all machine traffic, and resets when the process restarts.

## Troubleshooting

- **Unsupported version or interface:** use Comigo v1.3.5 or later and check `comi desktop info` for local desktop integration.
- **Offline or startup timeout:** check the connection URL against the actual server configuration and inspect Service logs. URL settings do not reconfigure the server.
- **No IP arrows:** confirm Local mode, external access, and more than one available IP.
- **Anonymous login controls are disabled:** they become available when authentication is required or a login session exists.
- **Panel does not reflect installed code:** run `omarchy restart shell`, then reopen it.

## Development

For a local source checkout:

```bash
git clone https://github.com/yumenaka/comigo-omarchy.git
cd comigo-omarchy
bash install.sh
```

The script validates and copies the plugin, restarts Omarchy Shell, and enables it. Rerun it to synchronize a checkout. A Shell restart closes its popups and clears plugin login sessions; an already running Comigo service continues running.

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

QML tests require a Wayland session. Integration tests use an isolated service. See [development instructions](AGENTS.md), [Comigo documentation](https://github.com/yumenaka/comigo#readme), and the built-in manual at `/manual/en-US/comigo-omarchy` on your Comigo server.

## License and acknowledgments

MIT licensed; see [LICENSE](LICENSE). The interface is inspired by [omarchy-mihomo-plugin](https://github.com/lijiawei0305-pixel/omarchy-mihomo-plugin).
