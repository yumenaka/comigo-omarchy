#!/usr/bin/env bash
# 隔离 REST 替身验证模式、会话、草稿与本机操作边界。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-modes.XXXXXX")
export COMIGO_FIXTURE="$tmp" COMIGO_PLUGIN_SOURCE="$root"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
printf '%s\n' '{"serverURL":"http://127.0.0.1:1234/","remoteURL":"","cliPath":"/local/comi","libraryDir":"/local/books","language":"en"}' > "$tmp/config/omarchy-comigo/settings.json"
cat > "$tmp/bin/comigo-ctl" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
 status) printf '%s\n' '{"installed":false,"active":"inactive","version":"local-cli"}';;
 save-settings) exec bash "$COMIGO_PLUGIN_SOURCE/bin/comigo-ctl" "$@";;
 request)
  IFS= read -r token || true
  cat >/dev/null
  side=local; sent=10
  if [[ "$3" == *2234* ]]; then side=remote;sent=99;fi
  if [[ "$side:$token" == remote:local-session || "$side:$token" == local:remote-session ]]; then touch "$COMIGO_FIXTURE/leaked";fi
  sleep 0.3
  case "$4" in
   /api/server) printf '{"Version":"v1.3.6+%s-rest","readingURL":"http://127.0.0.1:1234/","localBrowserURL":"http://127.0.0.1:1234/","localIPs":["%s-ip"],"traffic":{"sentBytes":%s,"receivedBytes":1},"externalAccess":true}' "$side" "$side" "$sent";;
   /api/server/traffic) printf '{"sentBytes":%s,"receivedBytes":1}' "$sent";;
   /api/configs) printf '{"Port":1234,"ReadOnlyMode":false}';;
   /api/configs/status) printf '{"current":{"path":"/%s/config.toml","type":"cli","location":"Custom","format":"toml","exists":true}}' "$side";;
   *) touch "$COMIGO_FIXTURE/forbidden";exit 1;;
  esac
  printf '\n200';;
 *) touch "$COMIGO_FIXTURE/forbidden";exit 1;;
esac
BASH
ln -s "$root" "$tmp/qml/Plugin"
ln -s /usr/share/omarchy/shell/Commons "$tmp/qml/Commons"
ln -s /usr/share/omarchy/shell/Ui "$tmp/qml/Ui"
cat > "$tmp/qml/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "Plugin" as Comigo
ShellRoot {
 id:test
 Comigo.Service {id:svc;manifest:({__sourceDir:Quickshell.env("COMIGO_FIXTURE")})}
 // REST 替身不提供二维码；停留服务页，概览与二维码由真实服务 smoke 测试覆盖。
 Comigo.Panel {id:panel;serviceOverride:svc;onPageChanged:if(page==="home")goto("service")}
 Comigo.SettingsPage {id:settingsPage;svc:svc}
 Comigo.ServerPage {id:serverPage;svc:svc}
 property int step:0
 property int ticks:0
 property bool mixed:false
 Connections {target:svc;function onInfoChanged(){if(svc.remote && svc.info.Version==="v1.3.6+local-rest")test.mixed=true}}
 function find(item,name) {if(item.objectName===name)return item;for(var i=0;i<item.children.length;i++){var result=find(item.children[i],name);if(result)return result}return null}
 function fail(message) {console.error("MODES_FAIL",step,message);Qt.quit()}
 Timer {
  interval:100;running:true;repeat:true
  onTriggered:{
   if(++test.ticks>250){test.fail("timeout");return}
   if(svc.busy || svc.pendingHTTP || svc.localPending)return
   if(test.step===0 && svc.connected && svc.localChecked){
    if(svc.mode!=="local" || panel.page!=="service"){test.fail("initial local mode");return}
    if(find(settingsPage,"loginCard").enabled || find(settingsPage,"username").enabled || find(settingsPage,"password").enabled){test.fail("anonymous login controls enabled");return}
    svc.token="local-session"
    if(!find(settingsPage,"loginCard").enabled){test.fail("authenticated session controls disabled");return}
    svc.setMode("remote");test.step=1;return
   }
   if(test.step===1){
    if(panel.page!=="config" || svc.endpoint || svc.connected || svc.version!=="—" || svc.token){test.fail("empty remote mode");return}
    if(find(settingsPage,"accessCard").visible || find(settingsPage,"firewallCard").visible || find(serverPage,"localControlCard").visible){test.fail("local UI in remote mode");return}
    // 即使直接调用入口，也不能在远程模式执行本地管理操作。
    svc.control("start");svc.firewall("open");svc.runLocal("restart",[])
    var library=find(settingsPage,"libraryDir");library.text="/unsaved-local";library.textEdited()
    var remote=find(settingsPage,"remoteURL");remote.text="http://127.0.0.1:2234/books/";remote.textEdited()
    find(settingsPage,"saveSettings").clicked();test.step=2;return
   }
   if(test.step===2 && svc.connected){
    if(svc.version!=="v1.3.6+remote-rest" || svc.readingURL!=="http://127.0.0.1:2234/books/" || svc.browserURL!==svc.readingURL || svc.settings.libraryDir!=="/local/books" || svc.settings.serverURL!=="http://127.0.0.1:1234/" || svc.info.localIPs[0]!=="remote-ip"){test.fail("remote data or settings isolation");return}
    svc.token="remote-session";svc.loadConfig();test.step=3;return
   }
   if(test.step===3 && svc.configFileStatus){
    if(svc.configFileStatus.path!=="/remote/config.toml" || svc.traffic.sentBytes!==99){test.fail("remote config and traffic");return}
    svc.setMode("local");test.step=5;return
   }
   if(test.step===5 && svc.connected){
    if(svc.version!=="v1.3.6+local-rest" || svc.token!=="local-session" || !find(settingsPage,"accessCard").visible || !find(settingsPage,"firewallCard").visible || find(settingsPage,"libraryDir").text!=="/unsaved-local"){test.fail("local session or draft restoration");return}
    // 切换时让旧 HTTP 请求继续完成，确认响应不会混入新服务。
    svc.refresh(false);svc.setMode("remote");test.step=6;return
   }
   if(test.step===6 && svc.connected){
    if(test.mixed || svc.version!=="v1.3.6+remote-rest" || svc.token!=="remote-session"){test.fail("stale response or session mixing");return}
    svc.refresh(false);svc.logout();test.step=7;return
   }
   if(test.step===7){
    if(svc.connected || svc.token || !svc.needsLogin || Object.keys(svc.info).length){test.fail("logout restored stale state");return}
    svc.setMode("local");test.step=8;return
   }
   if(test.step===8 && svc.connected){
    if(svc.token!=="local-session"){test.fail("logout affected other session");return}
    svc.setMode("remote");test.step=9;return
   }
   if(test.step===9){
    if(svc.token || !svc.needsLogin){test.fail("forgotten remote session restored");return}
    console.log("COMIGO_MODES_OK");Qt.quit()
   }
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
output=$(< "$tmp/result.log")
[[ "$output" == *COMIGO_MODES_OK* && "$output" != *MODES_FAIL* && "$output" != *'WARN scene'* && ! -e "$tmp/forbidden" && ! -e "$tmp/leaked" ]]
echo 'Local/remote modes, UI, drafts and session isolation passed'
