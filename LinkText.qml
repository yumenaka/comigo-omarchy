import QtQuick
import qs.Commons
import qs.Commons as Commons

// HTTP(S) 地址保持纯文本显示，统一支持鼠标、键盘和辅助功能打开链接。
Text {
  id: root
  readonly property bool isLink: /^https?:\/\/[^\s]+$/i.test(text)
  function openLink() {if(isLink)Qt.openUrlExternally(text)}
  textFormat: Text.PlainText
  color: isLink ? Commons.Color.accent : Commons.Color.popups.text
  font.underline: isLink
  activeFocusOnTab: isLink
  Accessible.role: isLink ? Accessible.Link : Accessible.StaticText
  Accessible.name: text
  Accessible.onPressAction: openLink()
  Keys.onReturnPressed: openLink()
  Keys.onEnterPressed: openLink()
  Keys.onSpacePressed: openLink()
  Rectangle {anchors.fill:parent;color:"transparent";border.color:Commons.Color.accent;border.width:root.activeFocus && root.isLink ? 1 : 0}
  MouseArea {
    anchors.fill: parent
    enabled: root.isLink
    cursorShape: Qt.PointingHandCursor
    onClicked: {root.forceActiveFocus(Qt.MouseFocusReason);root.openLink()}
  }
}
