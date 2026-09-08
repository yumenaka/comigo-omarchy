import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

// 所有页面共用轻量按钮，保持鼠标、Tab 和键盘激活行为一致。
Controls.Button {
  id: root
  property bool primary: false
  implicitHeight: Style.space(32)
  implicitWidth: label.implicitWidth + Style.space(22)
  opacity: enabled ? 1 : 0.4
  leftPadding: Style.space(10)
  rightPadding: Style.space(10)
  contentItem: Text {
    id: label
    text: root.text
    textFormat: Text.PlainText
    // 可点击文字始终不透明，禁用状态统一由按钮整体 opacity 表达。
    color: Util.alpha(root.primary ? Color.accent : Color.popups.text, 1)
    font.family: Style.font.family
    font.pixelSize: Style.font.bodySmall
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }
  background: Rectangle {
    radius: Style.cornerRadius
    color: Util.alpha(root.primary ? Color.accent : Color.popups.text, root.down ? 0.2 : root.hovered ? 0.12 : root.primary ? 0.1 : 0.025)
    border.width: 1
    border.color: Util.alpha(root.primary || root.activeFocus ? Color.accent : Color.popups.text, root.activeFocus ? 0.65 : 0.18)
  }
}
