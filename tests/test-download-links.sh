#!/usr/bin/env bash
# 验证本机和远程均显示项目链接，且不再支持二进制安装命令。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-links.XXXXXX")
trap 'rm -rf -- "$tmp"' EXIT
export COMIGO_FIXTURE="$tmp" COMIGO_PLUGIN_SOURCE="$root"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
cat > "$tmp/bin/comigo-ctl" <<'CTL'
#!/usr/bin/env bash
set -euo pipefail
case "$1" in
 status) echo '{"installed":false,"active":"inactive"}';;
 request) cat >/dev/null; printf '{}\n000';;
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
 Comigo.Service {id:svc;manifest:({__sourceDir:Quickshell.env("COMIGO_FIXTURE")});function browse(url){openedURL=url}}
 Comigo.Panel {id:panel;serviceOverride:svc}
 Comigo.ServerPage {id:serverPage;svc:svc}
 property string openedURL:""
 function find(item,name) {if(item.objectName===name)return item;for(var i=0;i<item.children.length;i++){var result=find(item.children[i],name);if(result)return result}return null}
 Timer {
  interval:100;running:true;repeat:true
  onTriggered:{
   if(!svc.localChecked || svc.busy || svc.localPending)return
   if(panel.page!=="service" || !find(serverPage,"downloadCard").visible){console.error("LINKS_FAIL missing CLI");Qt.quit();return}
   find(serverPage,"githubLink").clicked()
   if(openedURL!=="https://github.com/yumenaka/comigo"){console.error("LINKS_FAIL GitHub");Qt.quit();return}
   find(serverPage,"websiteLink").clicked()
   if(openedURL!=="https://comigo.xyz/"){console.error("LINKS_FAIL website");Qt.quit();return}
   svc.localInfo={installed:true}
   if(!find(serverPage,"downloadCard").visible){console.error("LINKS_FAIL installed");Qt.quit();return}
   svc.setMode("remote")
   if(!find(serverPage,"downloadCard").visible){console.error("LINKS_FAIL remote");Qt.quit();return}
   console.log("LINKS_OK");Qt.quit()
  }
 }
 Timer {interval:5000;running:true;onTriggered:{console.error("LINKS_FAIL timeout");Qt.quit()}}
}
QML
# 已移除的安装命令必须失败，不能执行下载或修改系统。
if output=$(bash "$root/bin/comigo-ctl" install); then exit 1; fi
[[ "$output" == '{"error":"unknown_action"}' ]]
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
output=$(< "$tmp/result.log")
[[ "$output" == *LINKS_OK* && "$output" != *LINKS_FAIL* ]]
echo 'Comigo download links passed'
