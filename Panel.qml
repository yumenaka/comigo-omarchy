import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// 固定导航栏与卡片页参考 Mihomo 插件；数据和进程操作交给共享 Service。
Panel {
  id:root
  moduleName:"yumenaka.comigo"
  manageIpc:false
  property var serviceOverride: null
  readonly property var svc: serviceOverride || (bar && bar.shell ? bar.shell.serviceFor(moduleName) : null)
  property string page:"home"
  property bool initialPageChosen:false
  property bool userSelectedPage:false
  function chooseInitialPage() {if(!initialPageChosen && svc && (svc.remote || svc.localChecked)){page=svc.remote ? (svc.endpoint ? "home" : "config") : svc.localInfo.installed ? "home" : "service";initialPageChosen=true}}
  onSvcChanged:Qt.callLater(chooseInitialPage)
  onOpenedChanged:if(opened && svc && !svc.remote && svc.localChecked && !svc.localInfo.installed)page="service"
  Connections {target:root.svc;function onModeChanged(){root.initialPageChosen=false;root.userSelectedPage=false;Qt.callLater(root.chooseInitialPage)}function onLocalCheckedChanged(){root.chooseInitialPage()} function onLocalInfoChanged(){if(!root.userSelectedPage){root.initialPageChosen=false;root.chooseInitialPage()}}}
  readonly property bool qrReady: homePage.qrStatus === Image.Ready
  readonly property var currentPage: page==="status" ? statusPage : page==="service" ? serverPage : page==="config" ? settingsPage : homePage
  readonly property var pageNames:["home","status","service","config"]
  implicitWidth:button.implicitWidth
  implicitHeight:button.implicitHeight
  function t(key) {return svc ? svc.t(key) : key}
  function goto(name) {if(pageNames.indexOf(name)>=0){userSelectedPage=true;page=name}}
  function cyclePage(direction) {goto(pageNames[(pageNames.indexOf(page)+direction+pageNames.length)%pageNames.length])}
  Binding {target:root.svc;property:"active";value:root.opened;when:!!root.svc}
  Binding {target:root.svc;property:"page";value:root.page;when:!!root.svc}
  // 只暴露无凭据的诊断快照，便于安装后检查真正加载的状态。
  IpcHandler {
    target:"yumenaka.comigo"
    function open():void {root.open()}
    function close():void {root.close()}
    function page(name:string):void {root.goto(name);root.open()}
    function mode(name:string):void {if(root.svc)root.svc.setMode(name);root.open()}
    function state():string {return JSON.stringify({mode:root.svc ? root.svc.mode : "local",page:root.page,opened:root.opened,connected:!!root.svc && root.svc.connected,installed:!!root.svc && root.svc.localInfo.installed,version:root.svc ? root.svc.version : "",traffic:root.svc ? root.svc.traffic : null})}
  }
  BarIconButton {
    id:button
    bar:root.bar
    anchors.fill:parent
    tooltipText:(root.svc ? root.svc.serviceName : "Comigo")+" · "+(root.svc ? root.svc.stateText : "—")
    // 离线时仍可点击打开面板，连接状态由面板中的状态文字表达。
    iconComponent:Component {Image {source:Qt.resolvedUrl("icon.png");fillMode:Image.PreserveAspectFit}}
    onPressed:function(mouseButton){if(mouseButton===Qt.MiddleButton && root.svc)root.svc.refresh();else root.toggle()}
  }
  KeyboardPanel {
    id:panel
    anchorItem:button
    owner:root
    bar:root.bar
    open:root.opened
    focusTarget:keys
    contentWidth:fittedContentWidth(Style.space(680))
    contentHeight:fittedContentHeight(Style.space(600),Style.space(600))
    PanelKeyCatcher {
      id:keys
      anchors.fill:parent
      blocked:root.currentPage.editing
      onCloseRequested:root.close()
      onTabRequested:function(direction){root.switchPanel(direction)}
      onMoveRequested:function(dx,dy){if(dy)root.currentPage.scrollBy(dy*Style.space(64));else if(dx)root.cyclePage(dx)}
      onTextKey:function(text){var index=Number(text)-1;if(index>=0 && index<root.pageNames.length)root.goto(root.pageNames[index]);else if(text==="r" && root.svc)root.svc.refresh()}
      Item {
        id:sidebar
        anchors.left:parent.left
        anchors.top:parent.top
        anchors.bottom:parent.bottom
        width:Style.space(116)
        Column {
          anchors.left:parent.left
          anchors.right:parent.right
          anchors.rightMargin:Style.space(12)
          spacing:Style.space(5)
          Row {
            width:parent.width;spacing:Style.space(7)
            Image {source:Qt.resolvedUrl("icon.png");width:Style.space(24);height:width;anchors.verticalCenter:parent.verticalCenter}
            Column {
              spacing:Style.space(2)
              Text {text:"COMIGO";color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.bodySmall;font.bold:true;font.letterSpacing:1}
              Text {text:root.svc ? root.svc.version : "—";textFormat:Text.PlainText;color:Util.alpha(Color.popups.text,0.45);font.family:Style.font.family;font.pixelSize:Style.font.caption}
            }
          }
          Item {width:1;height:Style.space(15)}
          Nav {name:"home";glyph:"󰋜";title:root.t("nav_home")}
          Nav {name:"status";glyph:"󰄨";title:root.t("nav_status")}
          Nav {name:"service";glyph:"󰒋";title:root.t("nav_service")}
          Nav {name:"config";glyph:"󰒓";title:root.t("nav_config")}
        }
        Column {
          anchors.left:parent.left
          anchors.right:parent.right
          anchors.rightMargin:Style.space(12)
          anchors.bottom:parent.bottom
          spacing:Style.space(10)
          Rectangle {width:parent.width;height:1;color:Util.alpha(Color.popups.text,0.12)}
          Row {
            width:parent.width;spacing:Style.space(3)
            Repeater {
              model:["local","remote"]
              Action {required property string modelData;objectName:"mode_"+modelData;width:(parent.width-parent.spacing)/2;leftPadding:0;rightPadding:0;text:root.t("mode_"+modelData);primary:root.svc && root.svc.mode===modelData;enabled:root.svc && !root.svc.busy;onClicked:root.svc.setMode(modelData)}
            }
          }
          Row {
            width:parent.width;spacing:Style.space(3)
            Repeater {
              model:[{code:"en",label:"EN"},{code:"zh",label:"中"},{code:"ja",label:"日"}]
              Action {required property var modelData;width:(parent.width-parent.spacing*2)/3;leftPadding:0;rightPadding:0;text:modelData.label;primary:root.svc && root.svc.language.slice(0,2)===modelData.code;enabled:root.svc && !root.svc.busy;onClicked:root.svc.setLanguage(modelData.code)}
            }
          }
          FooterStat {text:"↑ "+(root.svc ? root.svc.bytes(root.svc.traffic ? root.svc.traffic.sendBytesPerSecond : undefined):"—")+"/s"}
          FooterStat {text:"↓ "+(root.svc ? root.svc.bytes(root.svc.traffic ? root.svc.traffic.receiveBytesPerSecond : undefined):"—")+"/s"}
          FooterStat {text:root.svc ? root.svc.stateText : "—";color:root.svc && root.svc.connected ? Color.accent : Color.urgent}
        }
      }
      Rectangle {id:divider;anchors.left:sidebar.right;anchors.top:parent.top;anchors.bottom:parent.bottom;width:1;color:Util.alpha(Color.popups.text,0.12)}
      Item {
        anchors.left:divider.right
        anchors.leftMargin:Style.space(16)
        anchors.right:parent.right
        anchors.top:parent.top
        anchors.bottom:parent.bottom
        HomePage {id:homePage;anchors.fill:parent;visible:root.page==="home";svc:root.svc}
        StatusPage {id:statusPage;anchors.fill:parent;visible:root.page==="status";svc:root.svc}
        ServerPage {id:serverPage;anchors.fill:parent;visible:root.page==="service";svc:root.svc}
        SettingsPage {id:settingsPage;anchors.fill:parent;visible:root.page==="config";svc:root.svc}
        Rectangle {
          anchors.horizontalCenter:parent.horizontalCenter
          anchors.bottom:parent.bottom
          anchors.bottomMargin:Style.space(6)
          width:Math.min(parent.width,toast.implicitWidth+Style.space(24));height:toast.implicitHeight+Style.space(14)
          visible:root.svc && root.svc.notice!==""
          radius:Style.cornerRadius;color:Color.popups.background;border.width:1;border.color:Util.alpha(Color.accent,0.5)
          Text {id:toast;anchors.centerIn:parent;width:Math.min(implicitWidth,parent.width-Style.space(24));text:root.svc ? root.svc.notice : "";textFormat:Text.PlainText;wrapMode:Text.WordWrap;color:Color.popups.text;font.family:Style.font.family;font.pixelSize:Style.font.caption}
        }
      }
    }
  }
  component Nav: Action {
    required property string name
    required property string glyph
    required property string title
    width:parent.width
    text:glyph+"  "+title
    primary:root.page===name
    onClicked:root.goto(name)
    Rectangle {visible:parent.primary;anchors.left:parent.left;anchors.verticalCenter:parent.verticalCenter;width:Style.space(2);height:parent.height*0.55;color:Color.accent;radius:1}
  }
  component FooterStat: Text {width:parent.width;textFormat:Text.PlainText;elide:Text.ElideRight;color:Util.alpha(Color.popups.text,0.55);font.family:Style.font.family;font.pixelSize:Style.font.caption}
}
