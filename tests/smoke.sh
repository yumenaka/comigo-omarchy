#!/usr/bin/env bash
# 使用隔离书库、配置和端口验证 Comigo 与 Quickshell。
set -euo pipefail
: "${COMIGO_TEST_CLI:?Set COMIGO_TEST_CLI to the new Comigo executable}"
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
binary=$(realpath -- "$COMIGO_TEST_CLI")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-ui-test.XXXXXX")
mkdir -p "$tmp/books" "$tmp/config/omarchy-comigo" "$tmp/qml"
test_port=$((30000+RANDOM%20000))
while (exec 3<>"/dev/tcp/127.0.0.1/$test_port") 2>/dev/null; do test_port=$((test_port+1)); done
cat > "$tmp/reader.toml" <<CONFIG
Port = $test_port
BasePath = "/books"
DisableLAN = true
OpenBrowser = false
Username = "test"
Password = "test"
CacheDir = "$tmp/cache"
StoreUrls = ["$tmp/books"]
CONFIG
# 测试入口注入隔离配置，生产控制器只接收书库路径。
printf '#!/usr/bin/env bash\ncase "$1" in --version|--help|desktop) exec %q "$@";; *) exec %q --config %q "$@";; esac\n' "$binary" "$binary" "$tmp/reader.toml" > "$tmp/comi"
chmod +x "$tmp/comi"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:?}"
# 控制器运行记录与日志隔离，但保留 Quickshell 所需的真实 Wayland runtime。
ctl() { XDG_RUNTIME_DIR="$tmp/runtime" XDG_STATE_HOME="$tmp/state" bash "$root/bin/comigo-ctl" "$@"; }
endpoint="http://127.0.0.1:$test_port/books/"
trap 'ctl stop "$endpoint" >/dev/null || true' EXIT
ctl autostart "$endpoint" "$tmp/comi" "$tmp/books" >/dev/null
[[ -f "$tmp/runtime/omarchy-comigo/autostart-done" ]]
[[ $(ctl status "$COMIGO_TEST_CLI") == *'"active":"active"'* ]]
ctl restart "$endpoint" "$tmp/comi" "$tmp/books" >/dev/null
printf '{"serverURL":"http://127.0.0.1:%s/books/","cliPath":"%s","language":"en"}\n' "$test_port" "$COMIGO_TEST_CLI" > "$tmp/config/omarchy-comigo/settings.json"
ln -s "$root" "$tmp/qml/Plugin"
ln -s /usr/share/omarchy/shell/Commons "$tmp/qml/Commons"
ln -s /usr/share/omarchy/shell/Ui "$tmp/qml/Ui"
cat > "$tmp/qml/shell.qml" <<'QML'
import QtQuick
import Quickshell
import "Plugin" as Comigo
ShellRoot {
 Comigo.Service {id:svc}
 Comigo.Panel {id:panel;serviceOverride:svc}
 Comigo.SettingsPage {id:settingsPage;svc:svc}
 function find(item,name) {if(item.objectName===name)return item;for(var i=0;i<item.children.length;i++){var result=find(item.children[i],name);if(result)return result}return null}
 property int step:0
 property int attempts:0
 Timer {
  interval:250;running:true;repeat:true
  onTriggered:{
   attempts++
   if(attempts>160){console.error("SMOKE_FAIL timeout",step,svc.lastError);Qt.quit();return}
   if(svc.busy)return
   if(step===0 && svc.needsLogin && svc.localInfo.desktop){if(panel.page!=="home"){console.error("SMOKE_FAIL initial page");Qt.quit();return}if(!find(settingsPage,"loginCard").enabled || !find(settingsPage,"username").enabled || !find(settingsPage,"password").enabled){console.error("SMOKE_FAIL login controls disabled");Qt.quit();return}svc.login("test","test");step=1;return}
   if(step===1 && svc.connected && svc.traffic){
    if(svc.readingURL.indexOf("/books/")<0){console.error("SMOKE_FAIL BasePath");Qt.quit();return}
    svc.refreshTraffic();step=2;return
   }
   if(step===2){
    if(!svc.traffic || svc.traffic.sentBytes<=0){console.error("SMOKE_FAIL traffic");Qt.quit();return}
    var previous=Quickshell.clipboardText
    svc.copy("comigo-clipboard-test")
    var copied=Quickshell.clipboardText==="comigo-clipboard-test"
    Quickshell.clipboardText=previous
    if(!copied){console.error("SMOKE_FAIL clipboard");Qt.quit();return}
    // 验证四页循环回到概览，二维码仍由统一页面加载。
    panel.goto("home");panel.cyclePage(1)
    if(panel.page!=="status"){console.error("SMOKE_FAIL status navigation");Qt.quit();return}
    panel.cyclePage(1)
    if(panel.page!=="service"){console.error("SMOKE_FAIL service navigation");Qt.quit();return}
    panel.cyclePage(1)
    if(panel.page!=="config"){console.error("SMOKE_FAIL config navigation");Qt.quit();return}
    panel.cyclePage(1)
    if(panel.page!=="home"){console.error("SMOKE_FAIL overview navigation");Qt.quit();return}
    step=3;return
   }
   if(step===3 && panel.qrReady){panel.goto("config");svc.loadConfig();step=4;return}
   if(step===4 && svc.serverConfig.Port && svc.configFileStatus){
    if(!svc.configFileStatus.path.endsWith("/reader.toml") || svc.configFileStatus.type!=="cli" || svc.configFileStatus.location!=="Custom" || !svc.configFileStatus.exists){console.error("SMOKE_FAIL config file metadata");Qt.quit();return}
    if(svc.serverConfig.Password){console.error("SMOKE_FAIL leaked password");Qt.quit();return}
    if(svc.info.externalAccess!==false || svc.info.listenAddress!=="127.0.0.1"){console.error("SMOKE_FAIL local binding");Qt.quit();return}
    svc.setExternalAccess(true);step=40;return
   }
   if(step===40 && svc.connected && svc.info.externalAccess===true){
    if(svc.info.listenAddress!=="0.0.0.0"){console.error("SMOKE_FAIL LAN binding");Qt.quit();return}
    svc.setExternalAccess(false);step=41;return
   }
   if(step===41 && svc.connected && svc.info.externalAccess===false){
    if(svc.settings.libraryDir){console.error("SMOKE_FAIL unexpected library");Qt.quit();return}
    var next=Object.assign({},svc.settings);next.remoteURL=svc.endpoint+"/";svc.saveSettings(next);step=42;return
   }
   // 同一真实端点也按本机/远程分别认证，验证远程阅读完整保留 BasePath。
   if(step===42 && svc.settings.remoteURL){svc.setMode("remote");step=43;return}
   if(step===43 && svc.needsLogin){
    if(svc.token || !svc.remote){console.error("SMOKE_FAIL remote session isolation");Qt.quit();return}
    svc.login("test","test");step=44;return
   }
   if(step===44 && svc.connected){
    if(svc.browserURL!==svc.settings.remoteURL || svc.readingURL!==svc.settings.remoteURL || !svc.traffic){console.error("SMOKE_FAIL remote reading");Qt.quit();return}
    svc.setMode("local");step=45;return
   }
   if(step===45 && svc.connected){
    if(!svc.token){console.error("SMOKE_FAIL local session restoration");Qt.quit();return}
    svc.token="expired";svc.refresh();step=5;return
   }
   if(step===5 && svc.needsLogin){
    if(svc.token!=="" || svc.connected){console.error("SMOKE_FAIL expiry");Qt.quit();return}
    svc.setLanguage("ja");step=6;return
   }
   if(step===6 && svc.settings.language==="ja"){
    if(svc.t("nav_home")!=="概要"){console.error("SMOKE_FAIL locale");Qt.quit();return}
    panel.initialPageChosen=false;svc.localInfo={installed:false};panel.chooseInitialPage()
    if(panel.page!=="service"){console.error("SMOKE_FAIL missing CLI page");Qt.quit();return}
    console.log("COMIGO_SMOKE_OK");Qt.quit()
   }
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/qml.log" 2>&1
cat "$tmp/qml.log"
output=$(< "$tmp/qml.log")
[[ "$output" == *COMIGO_SMOKE_OK* && "$output" != *SMOKE_FAIL* && "$output" != *'WARN scene'* ]]
echo 'Real Comigo / curl / QML integration passed'
