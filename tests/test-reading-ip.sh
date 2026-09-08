#!/usr/bin/env bash
# 验证阅读 IP 切换、二维码绑定及选中样式。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-reading-ip.XXXXXX")
export COMIGO_FIXTURE="$tmp"
mkdir -p "$tmp/bin" "$tmp/config/omarchy-comigo" "$tmp/qml"
printf '%s\n' '{"serverURL":"http://127.0.0.1:1234/","language":"en"}' > "$tmp/config/omarchy-comigo/settings.json"
cat > "$tmp/bin/comigo-ctl" <<'CTL'
#!/usr/bin/env bash
set -eu
if [[ "$1" == status ]]; then printf '{"installed":true,"active":"active"}';exit;fi
cat >/dev/null
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
 Comigo.HomePage {id:home;svc:svc;width:420;height:600}
 function find(item,name) {if(item.objectName===name)return item;for(var i=0;i<item.children.length;i++){var result=find(item.children[i],name);if(result)return result}return null}
 function verify(condition,message) {if(!condition)throw new Error(message)}
 Timer {
  interval:1000;running:true
  onTriggered:{
   try {
    // 默认出口并非列表首项，切换必须保留协议、端口、路径和查询。
    var base="https://192.0.2.2:1234/books/?view=1"
    var ips=["192.0.2.1","192.0.2.2","2001:db8::1"]
    svc.info={readingURL:base,localIPs:ips};svc.connected=true
    verify(svc.readingURL===base,"default route")
    verify(find(home,"readingIP_192.0.2.2").valueBold,"default bold")
    verify(find(home,"nextReadingIP").visible,"multiple IP arrows")
    find(home,"nextReadingIP").clicked()
    verify(svc.readingURL==="https://[2001:db8::1]:1234/books/?view=1","IPv6 next")
    verify(svc.browserURL===svc.readingURL,"browser follows selection")
    verify(find(home,"readingIP_2001:db8::1").valueBold && !find(home,"readingIP_192.0.2.2").valueBold,"selected bold")
    verify(String(find(home,"readingQR").source).indexOf(encodeURIComponent(svc.readingURL))>=0,"QR follows selection")
    svc.info={readingURL:base,localIPs:ips.slice()}
    verify(svc.currentReadingIP==="2001:db8::1","poll retains selection")
    find(home,"nextReadingIP").clicked()
    verify(svc.currentReadingIP==="192.0.2.1","wrap forward")
    find(home,"previousReadingIP").clicked()
    verify(svc.currentReadingIP==="2001:db8::1","wrap backward")
    svc.info={readingURL:base,localIPs:["192.0.2.2"]}
    verify(svc.readingURL===base && !find(home,"nextReadingIP").visible,"removed IP fallback and single IP")
    // 仅本机监听时必须清除网卡选择，不能生成无法访问的局域网链接。
    svc.info={readingURL:base,localIPs:ips,externalAccess:true};svc.cycleReadingIP(1)
    svc.info={readingURL:"http://127.0.0.1:1234/books/",localIPs:ips,externalAccess:false}
    svc.cycleReadingIP(1)
    verify(svc.readingURL==="http://127.0.0.1:1234/books/" && !svc.selectedReadingIP,"local-only URL")
    verify(!find(home,"nextReadingIP").visible,"local-only arrows")
    svc.info={readingURL:base,localIPs:ips,externalAccess:true};svc.cycleReadingIP(1)
    svc.clearConnection()
    verify(!svc.selectedReadingIP,"connection reset")
    svc.settings=Object.assign({},svc.settings,{remoteURL:"https://reader.example/books/"});svc.mode="remote"
    svc.info={readingURL:base,localIPs:ips};svc.connected=true;svc.cycleReadingIP(1)
    verify(svc.readingURL==="https://reader.example/books/" && !find(home,"nextReadingIP").visible,"remote URL preserved")
    console.log("READING_IP_OK")
   } catch(error) {console.error("READING_IP_FAIL",error.message)}
   Qt.quit()
  }
 }
}
QML
XDG_CONFIG_HOME="$tmp/config" quickshell -p "$tmp/qml" > "$tmp/result.log" 2>&1
cat "$tmp/result.log"
output=$(< "$tmp/result.log")
[[ "$output" == *READING_IP_OK* && "$output" != *READING_IP_FAIL* ]]
echo 'Reading IP navigation and QR checks passed'
