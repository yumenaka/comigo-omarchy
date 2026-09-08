#!/usr/bin/env bash
# 校验、复制并启用本地插件。
set -euo pipefail
plugin_source=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
plugin_target="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/plugins/yumenaka.comigo"
owned=false
if [[ -f "$plugin_target/.local-source" && ! -L "$plugin_target" && ! -e "$plugin_target/.git" ]]; then
  marker=""; IFS= read -r marker < "$plugin_target/.local-source" || true
  [[ "$marker" != "$plugin_source" ]] || owned=true
fi
if [[ "${1:-}" == --uninstall ]]; then
  [[ "$owned" == true ]] || { echo 'No matching local installation.' >&2; exit 1; }
  omarchy plugin disable yumenaka.comigo
  rm -rf -- "$plugin_target"
  exit 0
fi
[[ $# -eq 0 ]] || { echo 'Usage: bash install.sh [--uninstall]' >&2; exit 1; }
for dependency in omarchy curl; do command -v "$dependency" >/dev/null || { echo "Missing dependency: $dependency" >&2; exit 1; }; done
if [[ -e "$plugin_target" || -L "$plugin_target" ]]; then
  [[ "$owned" == true ]] || { echo 'Plugin path belongs to another installation.' >&2; exit 1; }
fi
omarchy plugin validate "$plugin_source"
# 暂存并校验完整副本，避免复制过程被热重载读到半成品。
stage=$(mktemp -d "${TMPDIR:-/tmp}/omarchy-comigo-install.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT
mkdir "$stage/plugin"
cp -- "$plugin_source"/*.qml "$plugin_source"/*.js "$plugin_source"/*.json "$plugin_source"/*.png "$plugin_source"/*.md "$plugin_source/LICENSE" "$plugin_source/install.sh" "$stage/plugin/"
cp -R -- "$plugin_source/bin" "$plugin_source/tests" "$stage/plugin/"
printf '%s\n' "$plugin_source" > "$stage/plugin/.local-source"
omarchy plugin validate "$stage/plugin"
mkdir -p -- "${plugin_target%/*}"
[[ "$owned" != true ]] || mv -- "$plugin_target" "$stage/previous"
if ! mv -- "$stage/plugin" "$plugin_target"; then
  [[ ! -d "$stage/previous" ]] || mv -- "$stage/previous" "$plugin_target"
  exit 1
fi
# 重启 Shell，让运行中的插件使用安装目录的 QML 组件。
omarchy restart shell
# Omarchy 注册表异步扫描；读取 JSON 只查固定插件 ID。
plugin_found=false
for ((attempt=0;attempt<30;attempt++)); do
  plugins=$(omarchy plugin list --json)
  if [[ "$plugins" == *'"id":"yumenaka.comigo"'* || "$plugins" == *'"id": "yumenaka.comigo"'* ]]; then plugin_found=true;break;fi
  sleep 0.2
done
[[ "$plugin_found" == true ]] || { echo 'Plugin discovery timed out.' >&2; exit 1; }
omarchy plugin enable yumenaka.comigo
