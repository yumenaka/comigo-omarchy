import QtQuick
import qs.Commons

Page {
  id:root
  // 阅读地址与操作置于二维码下方。
  readonly property int qrStatus: qr.status
  title:t("nav_home")
  subtitle:svc ? svc.serviceName : ""
  Card {
    width:parent.width
    Text {text:root.t("qr");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    Text {visible:qr.status===Image.Error;text:root.t("qr_error");color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.caption}
    Item {
      width:parent.width;height:Style.space(210)
      Image {
        id:qr
        objectName:"readingQR"
        visible:root.svc && root.svc.connected
        anchors.centerIn:parent
        width:Style.space(210);height:width
        source:root.visible && root.svc && root.svc.connected ? root.svc.endpoint+"/api/qrcode.png?qrcode_str="+encodeURIComponent(root.svc.readingURL) : ""
        fillMode:Image.PreserveAspectFit
        smooth:false
      }
      Action {
        objectName:"previousReadingIP";text:"◀";Accessible.name:root.t("previous_ip")
        anchors.right:qr.left;anchors.rightMargin:Style.space(8);anchors.verticalCenter:qr.verticalCenter
        visible:root.svc && root.svc.connected && root.svc.readingIPs.length>1
        onClicked:root.svc.cycleReadingIP(-1)
      }
      Action {
        objectName:"nextReadingIP";text:"▶";Accessible.name:root.t("next_ip")
        anchors.left:qr.right;anchors.leftMargin:Style.space(8);anchors.verticalCenter:qr.verticalCenter
        visible:root.svc && root.svc.connected && root.svc.readingIPs.length>1
        onClicked:root.svc.cycleReadingIP(1)
      }
    }
    Text {text:root.t("reading");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    Text {width:parent.width;text:root.svc ? root.svc.readingURL || "—" : "—";textFormat:Text.PlainText;wrapMode:Text.WrapAnywhere;color:Color.accent;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall}
    Row {spacing:Style.space(8);Action {text:root.t("open");primary:true;enabled:root.svc && !!root.svc.browserURL;onClicked:root.svc.browse(root.svc.browserURL)} Action {text:root.t("copy");enabled:root.svc && !!root.svc.readingURL;onClicked:root.svc.copy(root.svc.readingURL)}}
  }
  Card {
    width:parent.width
    Text {text:root.t(root.svc && root.svc.remote ? "remote_ips" : "ips");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    Repeater {
      model:root.svc ? root.svc.info.localIPs || [] : []
      InfoRow {required property string modelData;width:parent.width;objectName:"readingIP_"+modelData;label:"IP";value:modelData;valueBold:root.svc && root.svc.currentReadingIP===modelData}
    }
    Text {visible:!root.svc || !root.svc.connected;text:root.t("offline");color:Util.alpha(Color.popups.text,0.5);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Text {visible:root.svc && (root.svc.unsupportedServer || (root.svc.connected && !root.svc.traffic));width:parent.width;text:root.t("unsupported");wrapMode:Text.WordWrap;color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.caption}
}
