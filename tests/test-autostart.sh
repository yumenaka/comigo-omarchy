#!/usr/bin/env bash
# 隔离 QML 启动调度，验证三次失败后不会继续重试。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-autostart.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
export COMIGO_FIXTURE="$tmp"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
printf '%s\n' '{"serverURL":"http://127.0.0.1:1234/","libraryDir":"/fixture","autoStart":true}' > "$tmp/config/omarchy-comigo/settings.json"
cat > "$tmp/bin/comigo-ctl" <<'CTL'
#!/usr/bin/env bash
case "$1" in
 status) echo '{"installed":true,"active":"inactive"}';;
 request) cat >/dev/null; printf '{}\n000';;
 autostart) echo attempt >> "$COMIGO_FIXTURE/attempts"; echo '{"error":"service_error"}'; exit 1;;
 *) exit 1;;
esac
CTL
ln -s "$root" "$tmp/qml/Plugin"
ln -s /usr/share/omarchy/shell/Commons "$tmp/qml/Commons"
ln -s /usr/share/omarchy/shell/Ui "$tmp/qml/Ui"
cat > "$tmp/qml/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "Plugin" as Comigo
ShellRoot {
 Comigo.Service {id:svc;manifest:({__sourceDir:Quickshell.env("COMIGO_FIXTURE")})}
 Timer {
  interval:42000;running:true
  onTriggered:{
   if(svc.autoStartAttempts===3 && !svc.localPending)console.log("AUTOSTART_OK")
   else console.error("AUTOSTART_FAIL",svc.autoStartAttempts)
   Qt.quit()
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
[[ $(< "$tmp/result.log") == *AUTOSTART_OK* ]]
[[ $(wc -l < "$tmp/attempts") -eq 3 ]]
