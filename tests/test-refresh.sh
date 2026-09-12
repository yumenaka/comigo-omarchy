#!/usr/bin/env bash
# 隔离文件与 REST 替身验证后台轮询、外部配置更新及草稿保护。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-refresh.XXXXXX")
export COMIGO_FIXTURE="$tmp" COMIGO_PLUGIN_SOURCE="$root"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
cat > "$tmp/config/omarchy-comigo/settings.json" <<'JSON'
{"serverURL":"http://127.0.0.1:1234/","cliPath":"/fake/comi","libraryDir":"/initial","language":"en"}
JSON
cat > "$tmp/server.json" <<'JSON'
{"Version":"v1.3.6","externalAccess":false,"listenAddress":"127.0.0.1","localIPs":["192.0.2.1"],"traffic":{"sentBytes":0,"receivedBytes":0,"sendBytesPerSecond":0,"receiveBytesPerSecond":0}}
JSON
printf '%s\n' '{"current":{"path":"/config/reader.toml","location":"Custom","type":"cli","format":"toml","exists":true}}' > "$tmp/files.json"
printf '%s\n' '{"Port":1234,"ReadOnlyMode":false}' > "$tmp/configs.json"
cat > "$tmp/bin/comigo-ctl" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
 status) sleep 0.1;printf '%s\n' '{"installed":true,"desktop":true,"active":"active","version":"test","cliPath":"/fake/comi"}';;
 request)
  cat >/dev/null
  sleep 0.15
  case "$4" in
   /api/server) cat "$COMIGO_FIXTURE/server.json";;
   /api/configs/status) cat "$COMIGO_FIXTURE/files.json";;
   /api/configs) cat "$COMIGO_FIXTURE/configs.json";;
   *) exit 1;;
  esac
  printf '\n200';;
 *) exec bash "$COMIGO_PLUGIN_SOURCE/bin/comigo-ctl" "$@";;
esac
BASH
cat > "$tmp/edit" <<'BASH'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
 settings) target="$XDG_CONFIG_HOME/omarchy-comigo/settings.json";;
 server|configs|files) target="$COMIGO_FIXTURE/$1.json";;
 *) exit 1;;
esac
printf '%s\n' "$2" > "$target.next"
mv -- "$target.next" "$target"
BASH
ln -s "$root" "$tmp/qml/Plugin"
ln -s /usr/share/omarchy/shell/Commons "$tmp/qml/Commons"
ln -s /usr/share/omarchy/shell/Ui "$tmp/qml/Ui"
cat > "$tmp/qml/shell.qml" <<'QML'
import QtQuick
import Quickshell
import Quickshell.Io
import "Plugin" as Comigo
ShellRoot {
 id:test
 Comigo.Service {id:svc;manifest:({__sourceDir:Quickshell.env("COMIGO_FIXTURE")});active:true;page:"config"}
 Comigo.SettingsPage {id:page;svc:svc}
 property bool queuedRead:false
 property int step:0
 property int ticks:0
 property int deadline:0
 property bool observe:false
 property int busyChanges:0
 property var snapshot:null
 property var traffic:null
 property var configs:null
 property var library:null
 property var cli:null
 function find(item,name){if(item.objectName===name)return item;var children=item.children || [];for(var i=0;i<children.length;i++){var found=find(children[i],name);if(found)return found}return null}
 function fail(message){console.error("REFRESH_FAIL",message,step);Qt.quit()}
 function edit(name,data){writer.command=["bash",Quickshell.env("COMIGO_FIXTURE")+"/edit",name,JSON.stringify(data)];writer.running=true}
 Connections {target:svc;function onBusyChanged(){if(test.observe)test.busyChanges++}}
 Process {id:writer;onExited:function(code){if(code!==0)test.fail("fixture write")}}
 Timer {
  interval:100;running:true;repeat:true
  onTriggered:{
   ticks++
   if(ticks>220){fail("timeout");return}
   if(writer.running)return
   if(step===0 && svc.connected && svc.serverConfig.Port && !svc.pendingHTTP && !svc.localPending){
    library=find(page,"libraryDir");cli=find(page,"cliPath")
    if(!library || library.text!=="/initial"){fail("initial field");return}
    snapshot=svc.info;traffic=svc.traffic;configs=svc.serverConfig;observe=true;deadline=ticks+45;step=1;return
   }
   if(step===1 && ticks>=deadline){
    observe=false
    if(busyChanges || snapshot!==svc.info || traffic!==svc.traffic || configs!==svc.serverConfig){fail("polling changed stable state");return}
    edit("settings",Object.assign({},svc.settings,{libraryDir:"/external",cliPath:"/external/comi"}));step=2;return
   }
   if(step===2 && library.text==="/external" && cli.text==="/external/comi"){
    library.text="/draft";library.textEdited()
    edit("settings",Object.assign({},svc.settings,{libraryDir:"/new-external",cliPath:"/new/comi"}));step=3;return
   }
   if(step===3 && cli.text==="/new/comi"){
    if(library.text!=="/draft" || !library.dirty){fail("draft overwritten");return}
    // 保存只合并草稿，保留其他字段的外部更新。
    if(svc.busy || svc.localPending)return
    svc.runLocal("status",[]);svc.saveSettings(Object.assign({},svc.settings,library.change()));step=4;return
   }
   if(step===4 && svc.settings.libraryDir==="/draft" && !svc.busy){
    if(library.dirty || svc.settings.cliPath!=="/new/comi"){fail("save merge");return}
    edit("configs",{Port:1234,ReadOnlyMode:true});step=5;return
   }
   if(step===5 && svc.serverConfig.ReadOnlyMode){
    var updated=JSON.parse(JSON.stringify(svc.info));updated.externalAccess=true;updated.listenAddress="0.0.0.0"
    edit("server",updated);step=6;return
   }
   if(step===6 && svc.info.externalAccess){
    var toggle=find(page,"externalAccess")
    if(!toggle.checked || toggle.enabled){fail("external switch/readonly");return}
    edit("files",{current:{path:"/new/config.toml",location:"HomeDirectory",type:"cli",format:"toml",exists:false}});step=60;return
   }
   if(step===60 && svc.configFileStatus && svc.configFileStatus.path==="/new/config.toml"){
    if(find(page,"configFilePath").value!=="/new/config.toml" || find(page,"configFileLocation").value!=="User directory (global)"){fail("read-only config file metadata");return}
    // 后台请求中发出的用户操作必须排队执行。
    if(svc.pendingHTTP || svc.busy)return
    svc.refresh(false);svc.request("GET","/api/configs/status",null,function(status,data){queuedRead=status===200 && data.current.path==="/new/config.toml"});step=7;return
   }
   if(step===7 && queuedRead){
    console.log("COMIGO_REFRESH_OK");Qt.quit()
   }
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
output=$(< "$tmp/result.log")
[[ "$output" == *COMIGO_REFRESH_OK* && "$output" != *REFRESH_FAIL* && "$output" != *'WARN scene'* ]]
echo 'Stable polling and external settings sync passed'
