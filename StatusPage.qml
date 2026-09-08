import QtQuick
import qs.Commons

// 状态页集中展示服务与流量统计。
Page {
  id:root
  title:t("nav_status")
  subtitle:svc ? svc.serviceName : ""
  Card {
    width:parent.width
    Text { text:root.t("server_status"); color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.bodySmall; font.bold:true }
    InfoRow {width:parent.width;label:root.t("status");value:root.svc ? root.svc.stateText : "—";valueColor:root.svc && root.svc.connected ? Color.accent : Color.urgent;valueBold:true}
    InfoRow {width:parent.width;label:root.t("version");value:root.svc ? root.svc.version : "—"}

  }
  Row {
    width:parent.width;spacing:Style.space(12)
    RateCard {width:(parent.width-parent.spacing)/2;title:"↑ "+root.t("sent");rate:root.svc && root.svc.traffic ? root.svc.traffic.sendBytesPerSecond : undefined}
    RateCard {width:(parent.width-parent.spacing)/2;title:"↓ "+root.t("received");rate:root.svc && root.svc.traffic ? root.svc.traffic.receiveBytesPerSecond : undefined}
  }
  Card {
    width:parent.width
    Text {text:root.t("total");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    Text {text:root.svc ? root.svc.bytes(root.svc.traffic ? root.svc.traffic.receivedBytes+root.svc.traffic.sentBytes : undefined) : "—";color:Color.accent;font.family:Style.font.family;font.pixelSize:Style.font.heading;font.bold:true}
    InfoRow {width:parent.width;label:root.t("sent");value:root.svc ? root.svc.bytes(root.svc.traffic ? root.svc.traffic.sentBytes : undefined) : "—"}
    InfoRow {width:parent.width;label:root.t("received");value:root.svc ? root.svc.bytes(root.svc.traffic ? root.svc.traffic.receivedBytes : undefined) : "—"}
    Text {width:parent.width;text:root.t("traffic_note");textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.5);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    width:parent.width
    InfoRow {width:parent.width;label:root.t("books");value:String(root.svc && root.svc.info.NumberOfBooks !== undefined ? root.svc.info.NumberOfBooks : "—")}
    InfoRow {width:parent.width;label:root.t("online_users");value:String(root.svc && root.svc.info.onlineUsers !== undefined ? root.svc.info.onlineUsers : "—")}
    InfoRow {width:parent.width;label:root.t("connections");value:String(root.svc && root.svc.info.connections !== undefined ? root.svc.info.connections : "—")}
  }
  component RateCard: Card {
    required property string title
    property var rate
    Text {text:parent.parent.title;color:Util.alpha(Color.popups.text,0.6);font.family:Style.font.family;font.pixelSize:Style.font.bodySmall}
    Text {text:(root.svc ? root.svc.bytes(parent.parent.rate) : "—")+"/s";color:Color.accent;font.family:Style.font.family;font.pixelSize:Style.font.heading;font.bold:true}
  }
}
