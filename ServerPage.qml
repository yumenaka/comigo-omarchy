import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.Commons

Page {
  id:root
  title:t("nav_service")
  subtitle:svc ? svc.serviceName : ""
  Card {
    width:parent.width
    objectName:"installCard"
    visible:root.svc && !root.svc.remote && !root.svc.localInfo.installed
    InfoRow {width:parent.width;label:root.t("install_path");value:root.svc ? root.svc.localInfo.installPath || "—" : "—"}
    Action {text:root.t(root.svc && root.svc.localPending ? "working" : "install_binary");primary:true;enabled:root.svc && !root.svc.busy;onClicked:root.svc.runLocal("install",[])}
    Text {width:parent.width;text:root.t("missing_cli");wrapMode:Text.WordWrap;color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    InfoRow {width:parent.width;label:root.t("install");value:"https://comigo.xyz/get.sh"}
    Row {spacing:Style.space(8);Action {text:root.t("install");onClicked:root.svc.browse("https://comigo.xyz/get.sh")} Action {text:root.t("copy_link");onClicked:root.svc.copy("https://comigo.xyz/get.sh")}}
    Action {text:root.t("install_command");onClicked:root.svc.copy("bash <(curl -s https://comigo.xyz/get.sh) --cn")}
    Row {spacing:Style.space(8);Action {text:root.t("website");onClicked:root.svc.browse("https://comigo.xyz/")} Action {text:root.t("copy_link");onClicked:root.svc.copy("https://comigo.xyz/")}}
  }
  Card {
    width:parent.width
    objectName:"localControlCard"
    visible:root.svc && !root.svc.remote
    InfoRow {width:parent.width;label:root.t("control");value:root.svc ? root.svc.stateText : "—";valueBold:true}
    InfoRow {width:parent.width;label:root.t("cli_path");value:root.svc ? root.svc.localInfo.cliPath || "—" : "—"}
    Row {
      spacing:Style.space(8)
      Action {text:root.t("start");primary:true;enabled:root.svc && !root.svc.busy && root.svc.localInfo.installed && root.svc.localInfo.active!=="active";onClicked:root.svc.control("start")}
      Action {text:root.t("stop");enabled:root.svc && !root.svc.busy && root.svc.localInfo.active==="active";onClicked:root.svc.control("stop")}
      Action {text:root.t("restart");enabled:root.svc && !root.svc.busy && root.svc.localInfo.installed;onClicked:root.svc.control("restart")}
    }
    Controls.Switch {
      objectName:"autoStart"
      text:root.t("auto_start")
      checked:root.svc && root.svc.settings.autoStart===true
      enabled:root.svc && !root.svc.busy
      onClicked:{root.svc.saveSettings(Object.assign({},root.svc.settings,{autoStart:checked}));checked=Qt.binding(function(){return root.svc && root.svc.settings.autoStart===true})}
      palette.windowText:Color.popups.text
      font.family:Style.font.family;font.pixelSize:Style.font.bodySmall
    }
    Text {width:parent.width;text:root.t("auto_start_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
    Action {text:root.t("logs");enabled:root.svc && !!root.svc.localInfo.logPath;onClicked:Quickshell.execDetached(["omarchy","launch","terminal","tail","-F",root.svc.localInfo.logPath])}
    Text {width:parent.width;visible:root.svc && !root.svc.settings.libraryDir;text:root.t("setup");textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    objectName:"remoteServiceCard"
    width:parent.width
    visible:root.svc && root.svc.remote
    InfoRow {width:parent.width;label:root.t("status");value:root.svc ? root.svc.stateText : "—"}
    InfoRow {width:parent.width;label:root.t("remote_endpoint");value:root.svc ? root.svc.endpoint || "—" : "—"}
    Action {text:root.t("refresh");enabled:root.svc && !root.svc.busy && !!root.svc.endpoint;onClicked:root.svc.refresh()}
  }
  Card {
    width:parent.width
    Text {text:root.t("check");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    InfoRow {width:parent.width;label:root.t("version");value:root.svc ? root.svc.version : "—"}
    Text {width:parent.width;text:!root.svc || root.svc.updateInfo.state==="unchecked" ? root.t("unchecked") : root.svc.updateInfo.state==="unknown" ? root.t("unknown") : root.svc.updateInfo.state==="error" ? root.t("http_error") : root.t(root.svc.updateInfo.available ? "available" : "latest")+" · "+root.svc.updateInfo.latestVersion;textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Color.accent;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall}
    Row {spacing:Style.space(8);Action {text:root.t("check");primary:true;enabled:root.svc && !root.svc.busy && (root.svc.connected || (!root.svc.remote && !!root.svc.localInfo.desktop));onClicked:root.svc.checkUpdate()} Action {text:root.t("release");onClicked:root.svc.browse(root.svc.updateInfo.releaseURL || "https://github.com/yumenaka/comigo/releases")}}
    Action {objectName:"upgradeCommand";visible:root.svc && !root.svc.remote;text:root.t("upgrade");onClicked:root.svc.copy(root.svc.upgradeCommand())}
  }

}
