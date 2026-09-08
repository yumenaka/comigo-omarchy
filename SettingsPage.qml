import QtQuick
import QtQuick.Controls as Controls
import qs.Commons

Page {
  id:root
  title:t("nav_config")
  subtitle:svc ? svc.serviceName : ""
  readonly property var firewall: svc && svc.localInfo.firewall ? svc.localInfo.firewall : ({})
  readonly property var currentFile: svc && svc.connected && svc.configFileStatus ? svc.configFileStatus : ({})
  editing:remoteEndpoint.activeFocus || endpoint.activeFocus || cli.activeFocus || library.activeFocus || username.activeFocus || password.activeFocus
  Connections {target:root.svc;function onConnectionKeyChanged(){username.clear();password.clear();username.dirty=false;password.dirty=false}}
  Card {
    objectName:"accessCard"
    width:parent.width
    visible:root.svc && !root.svc.remote
    Controls.Switch {
      id:accessSwitch
      objectName:"externalAccess"
      text:root.t("external_access")
      checked:root.svc && root.svc.info.externalAccess===true
      enabled:root.svc && root.svc.connected && !root.svc.busy && typeof root.svc.info.externalAccess==="boolean" && !root.svc.serverConfig.ReadOnlyMode
      onClicked:{root.svc.setExternalAccess(!root.svc.info.externalAccess);checked=Qt.binding(function(){return root.svc && root.svc.info.externalAccess===true})}
      palette.windowText:Util.alpha(Color.popups.text,1)
      font.family:Style.font.family;font.pixelSize:Style.font.bodySmall
    }
    InfoRow {width:parent.width;label:root.t("listen_address");value:root.svc ? root.svc.info.listenAddress || "—" : "—"}
    Text {width:parent.width;text:root.t("external_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    width:parent.width
    objectName:"firewallCard"
    visible:root.svc && !root.svc.remote
    InfoRow {width:parent.width;label:root.t("firewall");value:root.t(!root.firewall.supported ? "firewall_unavailable" : !root.firewall.enabled ? "firewall_disabled" : root.firewall.configured ? "firewall_configured" : "firewall_not_configured")}
    InfoRow {width:parent.width;label:root.t("firewall_scope");value:root.firewall.subnet ? root.firewall.subnet+" → TCP "+root.firewall.port+" · "+root.firewall.interface : root.t("lan_not_found")}
    Row {spacing:Style.space(8)
      Action {text:root.t("firewall_open");primary:true;enabled:root.svc && !root.svc.busy && root.svc.connected && !!root.svc.info.externalAccess && !!root.firewall.enabled && !!root.firewall.readable && !!root.firewall.subnet && !root.firewall.configured;onClicked:root.svc.firewall("open")}
      Action {text:root.t("firewall_close");enabled:root.svc && !root.svc.busy && root.firewall.ownedCount>0;onClicked:root.svc.firewall("close")}
    }
    Text {width:parent.width;text:root.t("firewall_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    width:parent.width
    Field {id:remoteEndpoint;objectName:"remoteURL";visible:root.svc && root.svc.remote;settingKey:"remoteURL";label:root.t("remote_endpoint");sourceValue:root.svc ? root.svc.settings.remoteURL || "" : "";placeholderText:"https://comigo.example/"}
    Field {id:endpoint;visible:root.svc && !root.svc.remote;objectName:"serverURL";settingKey:"serverURL";label:root.t("endpoint");sourceValue:root.svc ? root.svc.settings.serverURL : ""}
    Field {id:cli;visible:root.svc && !root.svc.remote;objectName:"cliPath";settingKey:"cliPath";label:root.t("cli_path");sourceValue:root.svc ? root.svc.settings.cliPath : "";placeholderText:root.t("auto_detect")}
    Field {id:library;visible:root.svc && !root.svc.remote;objectName:"libraryDir";settingKey:"libraryDir";label:root.t("library_dir");sourceValue:root.svc ? root.svc.settings.libraryDir : ""}
    Row {
      spacing:Style.space(8)
      Action {text:root.t("save");primary:true;enabled:root.svc && !root.svc.busy;objectName:"saveSettings";onClicked:root.svc.saveSettings(root.svc.remote ? Object.assign({},root.svc.settings,remoteEndpoint.change()) : Object.assign({},root.svc.settings,endpoint.change(),cli.change(),library.change()))}
    }
    Text {width:parent.width;text:root.t(root.svc && root.svc.remote ? "remote_config_note" : "config_note");textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  Card {
    width:parent.width
    InfoRow {objectName:"configFilePath";width:parent.width;label:root.t("config_file");value:root.currentFile.path || root.t(root.svc && root.svc.connected && root.svc.configFileStatus ? "config_memory" : "config_unavailable")}
    InfoRow {objectName:"configFileLocation";width:parent.width;label:root.t("config_location");value:root.currentFile.location ? root.t("location_"+root.currentFile.location) : "—"}
    InfoRow {objectName:"configFileType";width:parent.width;label:root.t("config_type");value:root.currentFile.type ? root.t("profile_"+root.currentFile.type)+" · "+String(root.currentFile.format || "").toUpperCase() : "—"}
    Text {width:parent.width;visible:!!root.currentFile.path && root.currentFile.exists===false;text:root.t("config_missing");wrapMode:Text.WordWrap;color:Color.urgent;font.family:Style.font.family;font.pixelSize:Style.font.caption}
    Action {text:root.t("manage_config");enabled:root.svc && !!root.svc.endpoint;onClicked:root.svc.browse(root.svc.endpoint+"/settings#config-container")}
  }
  Card {
    width:parent.width
    objectName:"loginCard"
    // 收到认证要求或已有登录会话时才允许操作，匿名连接禁用整组控件。
    enabled:root.svc && !root.svc.busy && (root.svc.needsLogin || root.svc.token!=="")
    opacity:enabled ? 1 : 0.5
    Text {text:root.t("login");color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true}
    Field {id:username;objectName:"username";label:root.t("username")}
    Field {id:password;objectName:"password";label:root.t("password");echoMode:TextInput.Password;onAccepted:loginButton.clicked()}
    Row {spacing:Style.space(8)
      Action {id:loginButton;text:root.t("login");primary:true;enabled:root.svc && !root.svc.busy && !!root.svc.endpoint && password.text!=="";onClicked:{if(!enabled)return;root.svc.login(username.text,password.text);password.clear()}}
      Action {text:root.t("logout");enabled:root.svc && root.svc.token!=="";onClicked:root.svc.logout()}
    }
    Text {width:parent.width;text:root.t("session_note");wrapMode:Text.WordWrap;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
  }
  component Field: Controls.TextField {
    id:field
    property string label: ""
    property string settingKey: ""
    property string sourceValue: ""
    property bool dirty:false
    // 未编辑字段跟随外部设置，草稿保留至用户保存。
    function syncValue() {
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
