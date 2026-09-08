import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

// 页头和滚动区域固定；切换页面不改变弹窗尺寸。
Item {
  id: root
  required property var svc
  property string title: ""
  property string subtitle: ""
  property bool editing: false
  default property alias content: column.data
  function t(key) { return svc ? svc.t(key) : key }
  function scrollBy(delta) { flick.contentY = Math.max(0,Math.min(Math.max(0,flick.contentHeight-flick.height),flick.contentY+delta)) }
  Column {
    id: header
    anchors.left: parent.left
    anchors.right: refresh.left
    anchors.rightMargin: Style.space(8)
    anchors.top: parent.top
    spacing: Style.space(3)
    Text { width:parent.width; text:root.title; textFormat:Text.PlainText; color:Color.popups.text; font.family:Style.font.family; font.pixelSize:Style.font.heading; font.bold:true }
    Text { width:parent.width; text:root.subtitle; textFormat:Text.PlainText; color:Util.alpha(Color.popups.text,0.5); font.family:Style.font.family; font.pixelSize:Style.font.caption; elide:Text.ElideMiddle }
  }
  Action { id:refresh; anchors.right:parent.right; anchors.top:parent.top; text:"󰑐"; width:Style.space(32); enabled:root.svc && !root.svc.busy; onClicked:root.svc.refresh(); Controls.ToolTip.visible:hovered; Controls.ToolTip.text:root.t("refresh") }
  Flickable {
    id:flick
    anchors.top:header.bottom
    anchors.topMargin:Style.space(16)
    anchors.left:parent.left
    anchors.right:parent.right
    anchors.bottom:parent.bottom
    contentWidth:width
    contentHeight:column.implicitHeight
    clip:true
    boundsBehavior:Flickable.StopAtBounds
    Controls.ScrollBar.vertical:Controls.ScrollBar {}
    Column {id:column;width:flick.width;spacing:Style.space(12)}
  }
}
