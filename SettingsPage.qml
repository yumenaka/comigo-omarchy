import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Page {
  id:root
  title:t("nav_config")
  subtitle:svc ? svc.serviceName : ""
  readonly property var currentFile: svc && svc.connected && svc.configFileStatus ? svc.configFileStatus : ({})
  property Item dialogHost: root
  property bool panelOpen: true
  readonly property Item loginFocus:loginDialog.visible ? username : null
  property bool loginPrompted:false
  readonly property bool loginRequired:svc && svc.reachable && svc.needsLogin && !svc.unsupportedServer && !svc.busy
  editing:endpoint.activeFocus || loginDialog.visible
  // 每次打开面板或保存地址只提示一次，取消后不被轮询打扰。
  function promptLogin(){
    if(panelOpen && visible && loginRequired && !loginPrompted){loginPrompted=true;loginDialog.open()}
  }
  onLoginRequiredChanged:Qt.callLater(promptLogin)
  onPanelOpenChanged:{if(!panelOpen){loginDialog.close();loginPrompted=false}else Qt.callLater(promptLogin)}
  onVisibleChanged:{if(!visible)loginDialog.close();else Qt.callLater(promptLogin)}
  Component.onCompleted:Qt.callLater(promptLogin)
  Connections {
    target:root.svc
    function onConnectionKeyChanged(){loginDialog.close();root.loginPrompted=false;Qt.callLater(root.promptLogin)}
    function onLoginFinished(success,errorKey){
      if(!loginDialog.visible)return
      loginDialog.submitting=false
      if(success)loginDialog.close()
      else {loginDialog.errorKey=errorKey;password.forceActiveFocus()}
    }
  }
  Card {
    objectName:"connectionCard"
    width:parent.width
    InfoRow {objectName:"connectionState";width:parent.width;label:root.t("server_status");value:root.svc ? root.svc.stateText : root.t("offline");valueBold:true}
    Text {objectName:"connectionHint";width:parent.width;text:root.svc ? root.svc.connectionHint : root.t("offline_note");textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.7);font.family:Style.font.family;font.pixelSize:Style.font.bodySmall}
    InfoRow {objectName:"connectionAddress";width:parent.width;label:root.t("endpoint");value:root.svc ? root.svc.endpoint+"/" : "—"}
    Action {objectName:"openService";text:root.t("open");visible:root.svc && root.svc.reachable;onClicked:root.svc.browse(root.svc.endpoint+"/")}
  }
  Card {
    width:parent.width
    Field {id:endpoint;objectName:"serverURL";settingKey:"serverURL";label:root.t("endpoint");sourceValue:root.svc ? root.svc.settings.serverURL : ""}
    Row {
      spacing:Style.space(8)
      Action {text:root.t(root.svc && root.svc.connected ? "disconnect" : "connect");enabled:!!root.svc;objectName:"saveSettings";onClicked:{if(root.svc.connected)root.svc.disconnectServer();else {root.loginPrompted=false;root.svc.connectServer(endpoint.change());Qt.callLater(root.promptLogin)}}}
    }
    Text {width:parent.width;text:root.t("api_config_note");textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
    Action {objectName:"logout";text:root.t("logout");visible:root.svc && root.svc.token!=="";enabled:root.svc && !root.svc.busy;onClicked:{root.loginPrompted=true;root.svc.logout()}}
  }
  Card {
    width:parent.width
    InfoRow {objectName:"configFilePath";width:parent.width;label:root.t("config_file");value:root.currentFile.path || root.t(root.svc && root.svc.connected && root.svc.configFileStatus ? "config_memory" : "config_unavailable")}
    InfoRow {objectName:"configFileLocation";width:parent.width;label:root.t("config_location");value:root.currentFile.location ? root.t("location_"+root.currentFile.location) : "—"}
    InfoRow {objectName:"configFileType";width:parent.width;label:root.t("config_type");value:root.currentFile.type ? root.t("profile_"+root.currentFile.type)+" · "+String(root.currentFile.format || "").toUpperCase() : "—"}
    Text {width:parent.width;visible:!!root.currentFile.path && root.currentFile.exists===false;text:root.t("config_missing");wrapMode:Text.WordWrap;color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.caption}
    Action {text:root.t("manage_config");enabled:root.svc && !!root.svc.endpoint;onClicked:root.svc.browse(root.svc.endpoint+"/settings#config-container")}
  }
  Controls.Dialog {
    id:loginDialog
    objectName:"loginDialog"
    parent:root.dialogHost
    anchors.centerIn:parent
    width:Math.min(parent.width,Style.space(380))
    modal:true
    focus:true
    popupType:Controls.Popup.Item
    closePolicy:Controls.Popup.CloseOnEscape | Controls.Popup.CloseOnPressOutside
    padding:Style.space(16)
    property bool submitting:false
    property string errorKey:""
    // 显式归还焦点；所有关闭路径都清空凭据，提交后立即清空密码。
    onOpened:{errorKey="";submitting=false;username.forceActiveFocus()}
    onClosed:{username.clear();password.clear();errorKey="";submitting=false;if(root.panelOpen && root.visible)endpoint.forceActiveFocus()}
    function submit(){
      if(!submitLogin.enabled)return
      errorKey="";submitting=true
      root.svc.login(username.text,password.text)
      password.clear()
    }
    background:Rectangle {color:Color.popups.background;radius:Style.cornerRadius;border.width:1;border.color:Color.accent}
    Controls.Overlay.modal:Item {
      // 遮罩只绘制在插件面板内，弹窗由 Qt 拦截底层输入。
      Rectangle {
        readonly property point origin:root.dialogHost.mapToItem(parent,0,0)
        x:origin.x;y:origin.y;width:root.dialogHost.width;height:root.dialogHost.height
        color:Util.alpha(Color.popups.background,0.7)
      }
    }
    header:Text {text:root.t("login_title");width:loginDialog.width; padding:Style.space(16);bottomPadding:0;wrapMode:Text.WordWrap;color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    contentItem:Column {
      spacing:Style.space(10)
      Field {id:username;objectName:"username";label:root.t("username");enabled:!loginDialog.submitting;onAccepted:password.forceActiveFocus()}
      Field {id:password;objectName:"password";label:root.t("password");echoMode:TextInput.Password;enabled:!loginDialog.submitting;onAccepted:loginDialog.submit()}
      Text {objectName:"loginError";width:parent.width;visible:loginDialog.errorKey!=="";text:visible ? root.t(loginDialog.errorKey) : "";textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.caption}
      Row {spacing:Style.space(8)
        Action {id:submitLogin;objectName:"submitLogin";text:root.t(loginDialog.submitting ? "logging_in" : "login");primary:true;enabled:!loginDialog.submitting && root.svc && !root.svc.busy && !!root.svc.endpoint && password.text!=="";onClicked:loginDialog.submit()}
        Action {objectName:"cancelLogin";text:root.t("cancel");onClicked:loginDialog.close()}
      }
      Text {width:parent.width;text:root.t("session_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
    }
  }
  component Field: Controls.TextField {
    id:field
    property string label: ""
    property string settingKey: ""
    property string sourceValue: ""
    property bool dirty:false
    // 未编辑字段跟随外部设置，草稿保留至用户保存。
    function syncValue() {
      if(!settingKey)return
      if(text===sourceValue)dirty=false
      if(!dirty && !activeFocus && text!==sourceValue)text=sourceValue
    }
    function change() {var result={};if(dirty)result[settingKey]=text;return result}
    onSourceValueChanged:syncValue()
    onActiveFocusChanged:if(!activeFocus)syncValue()
    onTextEdited:dirty=text!==sourceValue
    Component.onCompleted:syncValue()
    width:parent.width
    topPadding:Style.space(24)
    bottomPadding:Style.space(7)
    leftPadding:Style.space(9)
    rightPadding:Style.space(9)
    color:Color.popups.text
    placeholderTextColor:Util.alpha(Color.popups.text,0.35)
    font.family:Style.font.family
    font.pixelSize:Style.font.bodySmall
    selectByMouse:true
    background:Rectangle {radius:Style.cornerRadius;color:Util.alpha(Color.popups.text,0.025);border.width:1;border.color:Util.alpha(field.activeFocus ? Color.accent : Color.popups.text,field.activeFocus ? 0.65 : 0.12)}
    Text {anchors.left:parent.left;anchors.top:parent.top;anchors.margins:Style.space(8);text:field.label;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
}
