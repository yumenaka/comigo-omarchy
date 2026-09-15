import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Page {
  id:root
  title:t("nav_service")
  subtitle:svc ? svc.serviceName : ""
  Card {
    objectName:"accessCard"
    visible:root.svc && root.svc.localConnection
    width:parent.width
    Controls.Switch {
      id:accessSwitch
      objectName:"externalAccess"
      text:root.t("external_access")
      checked:root.svc && root.svc.info.externalAccess===true
      enabled:root.svc && root.svc.connected && !root.svc.busy && typeof root.svc.info.externalAccess==="boolean" && root.svc.serverConfig.ReadOnlyMode===false
      onClicked:{root.svc.setExternalAccess(!root.svc.info.externalAccess);checked=Qt.binding(function(){return root.svc && root.svc.info.externalAccess===true})}
      palette.windowText:Util.alpha(Color.popups.text,1)
      font.family:Style.font.family;font.pixelSize:Style.font.bodySmall
    }
    InfoRow {width:parent.width;label:root.t("listen_address");value:root.svc ? root.svc.info.listenAddress || "—" : "—"}
    Text {width:parent.width;text:root.t("external_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    objectName:"serviceCard"
    width:parent.width
    InfoRow {width:parent.width;label:root.t("status");value:root.svc ? root.svc.stateText : "—"}
    InfoRow {width:parent.width;label:root.t("endpoint");value:root.svc ? root.svc.endpoint || "—" : "—"}
    Action {text:root.t("refresh");enabled:root.svc && !root.svc.busy && !!root.svc.endpoint;onClicked:root.svc.refresh()}
  }
  Card {
    width:parent.width
    objectName:"downloadCard"
    InfoRow {width:parent.width;label:root.t("github");value:"https://github.com/yumenaka/comigo"}
    Row {spacing:Style.space(8);Action {objectName:"githubLink";text:root.t("open");onClicked:root.svc.browse("https://github.com/yumenaka/comigo")} Action {text:root.t("copy_link");onClicked:root.svc.copy("https://github.com/yumenaka/comigo")}}
    InfoRow {width:parent.width;label:root.t("website");value:"https://comigo.xyz/"}
    Row {spacing:Style.space(8);Action {objectName:"websiteLink";text:root.t("open");onClicked:root.svc.browse("https://comigo.xyz/")} Action {text:root.t("copy_link");onClicked:root.svc.copy("https://comigo.xyz/")}}
  }

}
