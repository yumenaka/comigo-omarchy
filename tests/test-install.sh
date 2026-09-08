#!/usr/bin/env bash
# 隔离安装流程，验证下载、保存、启动顺序以及失败时不启动、不跳页。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-install.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
export COMIGO_FIXTURE="$tmp" COMIGO_PLUGIN_SOURCE="$root"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
cat > "$tmp/bin/comigo-ctl" <<'CTL'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
 status) if [[ -f "$COMIGO_FIXTURE/installed" ]]; then echo '{"installed":true,"active":"inactive"}'; else echo '{"installed":false,"active":"inactive"}'; fi;;
 request) cat >/dev/null; printf '{}\n000';;
 install)
  echo install >> "$COMIGO_FIXTURE/actions"
  if [[ "$COMIGO_INSTALL_CASE" == download-failed ]]; then echo '{"error":"download_failed"}'; exit 1; fi
  touch "$COMIGO_FIXTURE/installed"
  echo '{"cliPath":"/fixture/downloaded comi"}';;
 save-settings)
  echo save >> "$COMIGO_FIXTURE/actions"
  if [[ "$COMIGO_INSTALL_CASE" == save-failed ]]; then cat >/dev/null; echo '{"error":"invalid_settings"}'; exit 1; fi
  exec bash "$COMIGO_PLUGIN_SOURCE/bin/comigo-ctl" "$@";;
 start)
  [[ "$2" == http://127.0.0.1:1234/ && "$3" == '/fixture/downloaded comi' && "$4" == '' ]]
  echo start >> "$COMIGO_FIXTURE/actions"
  if [[ "$COMIGO_INSTALL_CASE" == start-failed ]]; then echo '{"error":"service_error"}'; exit 1; fi
  echo '{"ok":true}';;
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
 Comigo.Panel {id:panel;serviceOverride:svc}
 property bool attempted:false
 Timer {
  interval:100;running:true;repeat:true
  onTriggered:{
   if(!attempted && svc.settingsLoaded && svc.localChecked && !svc.busy && !svc.localPending){
    if(panel.page!=="service"){console.error("INSTALL_FAIL initial page");Qt.quit();return}
    attempted=true;svc.runLocal("install",[])
   }
  }
 }
 Timer {
  interval:2500;running:true
  onTriggered:{
   if(attempted && !svc.localPending && !svc.installedCLI && panel.page==="service")console.log("INSTALL_OK")
   else console.error("INSTALL_FAIL",panel.page,svc.localAction)
   Qt.quit()
  }
 }
}
QML
for scenario in success start-failed download-failed save-failed; do
 export COMIGO_INSTALL_CASE="$scenario"
 rm -f "$tmp/installed" "$tmp/actions" "$tmp/config/omarchy-comigo/settings.json"
 XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
 cat "$tmp/result.log"
 [[ $(< "$tmp/result.log") == *INSTALL_OK* ]]
 expected=$'install\nsave\nstart'
 if [[ "$scenario" == download-failed ]]; then expected=install; fi
 if [[ "$scenario" == save-failed ]]; then expected=$'install\nsave'; fi
 [[ $(< "$tmp/actions") == "$expected" ]]
done
echo 'Comigo installation flow passed'
