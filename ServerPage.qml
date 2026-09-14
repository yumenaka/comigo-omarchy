import QtQuick
import qs.Commons

Page {
  id:root
  title:t("nav_service")
  subtitle:svc ? svc.serviceName : ""
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
