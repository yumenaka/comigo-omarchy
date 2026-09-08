#!/usr/bin/env bash
# 验证最低服务版本，并确保 404 不触发旧接口回退。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-version.XXXXXX")
export COMIGO_FIXTURE="$tmp"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
printf '%s\n' '{"serverURL":"http://127.0.0.1:1234/","libraryDir":"/test/books","language":"en"}' > "$tmp/config/omarchy-comigo/settings.json"
cat > "$tmp/bin/comigo-ctl" <<'CTL'
#!/usr/bin/env bash
set -eu
if [[ "$1" == status ]]; then printf '{"installed":true,"active":"active","version":"v1.3.4"}';exit;fi
cat >/dev/null
if [[ "$1" != request || "$4" != /api/server ]]; then touch "$COMIGO_FIXTURE/forbidden";exit 1;fi
printf '{}\n404'
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
 property int ticks:0
 function verify(condition,message) {if(!condition)throw new Error(message)}
 Timer {
  interval:100;running:true;repeat:true
  onTriggered:{
   if(++ticks>100){console.error("VERSION_FAIL timeout");Qt.quit();return}
   if(!svc.unsupportedServer || svc.pendingHTTP || svc.localPending)return
   try {
    verify(!svc.connected && svc.stateText===svc.t("unsupported"),"404 message")
    var rejected=["v1.3.4","v1.2.99","v0.9.99","v1.3.5-rc.1","invalid",""]
    for(var i=0;i<rejected.length;i++){
     svc.receiveServer(200,{Version:rejected[i]})
     verify(!svc.connected && svc.unsupportedServer,"accepted "+rejected[i])
    }
    var accepted=["v1.3.5","1.3.5","v1.3.5+build","v1.3.10","v1.4.0","v2.0.0"]
    for(i=0;i<accepted.length;i++){
     svc.receiveServer(200,{Version:accepted[i]})
     verify(svc.connected && !svc.unsupportedServer,"rejected "+accepted[i])
    }
    svc.receiveServer(0,{})
    verify(!svc.connected && !svc.unsupportedServer,"network error")
    svc.receiveServer(404,{})
    svc.clearConnection()
    verify(!svc.connected && !svc.unsupportedServer,"connection reset")
    console.log("COMIGO_VERSION_OK")
   } catch(error) {console.error("VERSION_FAIL",error.message)}
   Qt.quit()
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
output=$(< "$tmp/result.log")
[[ "$output" == *COMIGO_VERSION_OK* && "$output" != *VERSION_FAIL* && ! -e "$tmp/forbidden" ]]
echo 'Minimum version and no-fallback checks passed'
