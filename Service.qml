import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model
import "I18n.js" as I18n

// 统一 REST 客户端；宿主管理界面设置，令牌仅保留在内存。
Item {
  id: root
  property var manifest: null
  property var shell: null
  readonly property var defaultSettings: ({serverURL:"http://127.0.0.1:1234/",language:"auto"})
  property var settings: Object.assign({},defaultSettings)
  property bool settingsLoaded: false
  property bool active: false
  property string page: "home"
  property bool connected: false
  property bool manuallyDisconnected: false
  property bool reachable: false
  property bool unsupportedServer: false
  property bool needsLogin: false
  property var publicInfo: ({})
  property var info: ({})
  property var traffic: null
  property var serverConfig: ({})
  property var configFileStatus: null
  property string token: ""
  property string notice: ""
  property string lastError: ""
  property var pendingHTTP: null
  property bool httpBackground: false
  property var queuedRequest: null
  property string sessionKey: ""
  property var sessions: ({})
  property int generation: 0
  property var desiredExternalAccess: null
  property int reconnectAttempts: 0
  readonly property string endpoint: String(settings.serverURL || "").replace(/\/+$/, "")
  // 仅允许通过已保存的本机连接切换局域网共享，避免远程关闭后无法恢复。
  readonly property bool localConnection: ["127.0.0.1","localhost"].indexOf(Model.urlHost(endpoint).toLowerCase())>=0
  readonly property string connectionKey: endpoint
  readonly property string serviceName: "Comigo"
  readonly property string language: settings.language === "auto" ? Qt.locale().name : settings.language || "en"
  readonly property bool busy: (pendingHTTP !== null && !httpBackground) || queuedRequest !== null || desiredExternalAccess !== null
  readonly property string version: publicInfo.Version || info.Version || "—"
  property string selectedReadingIP: ""
  readonly property var readingIPs: info.externalAccess===false ? [] : (info.localIPs || []).filter(function(ip,index,ips){return ips.indexOf(ip)===index})
  // 配置地址是默认阅读入口，只有用户明确选择服务端返回的 IP 时才替换主机。
  readonly property string readingURL: selectedReadingIP && readingIPs.indexOf(selectedReadingIP)>=0 ? Model.withHost(endpoint+"/",selectedReadingIP) : endpoint+"/"
  readonly property string currentReadingIP: Model.urlHost(readingURL)
  readonly property string browserURL: readingURL
  readonly property string connectionState: manuallyDisconnected ? "disconnected" : desiredExternalAccess!==null ? "reconnecting" : connected ? "running" : unsupportedServer ? "unsupported" : !reachable ? (pendingHTTP!==null ? "connecting" : "offline") : needsLogin ? "needs_login" : "http_error"
  readonly property string stateText: t(connectionState)
  readonly property string connectionHint: t(connectionState+"_note")
  readonly property var hostEntry: findHostEntry(shell ? shell.barConfig : {})
  onHostEntryChanged: loadSettings()
  onReadingIPsChanged: if(readingIPs.indexOf(selectedReadingIP)<0)selectedReadingIP=""
  function cycleReadingIP(direction) {
    if(readingIPs.length<2)return
    var index=readingIPs.indexOf(currentReadingIP)
    selectedReadingIP=readingIPs[(index+direction+readingIPs.length)%readingIPs.length]
  }
  function updateSnapshot(name,value){var next=Model.reconcile(root[name],value);if(root[name]!==next)root[name]=next}
  function t(key){return I18n.text(key,language)}
  function bytes(value){return Model.bytes(value)}
  function tell(key){notice=t(key);toastTimer.restart()}
  function copy(value){Quickshell.clipboardText=String(value);tell("copied")}
  function browse(url){if(/^https?:\/\//.test(url))Qt.openUrlExternally(url)}
  function validURL(value){return /^https?:\/\/[^\s?#@]+(?:\/[^\s?#]*)?$/.test(value)}

  function findHostEntry(configuration) {
    var layout=configuration.layout || {},sections=["left","center","right"]
    for(var i=0;i<sections.length;i++) {
      var entries=layout[sections[i]] || []
      for(var j=0;j<entries.length;j++)if(entries[j].id==="yumenaka.comigo")return entries[j]
    }
    return {}
  }
  function loadSettings() {
    if(!shell)return
    var saved=hostEntry.comigo || {},next=Object.assign({},defaultSettings)
    if(saved.serverURL && validURL(saved.serverURL))next.serverURL=saved.serverURL
    if(["auto","en","zh","ja"].indexOf(saved.language)>=0)next.language=saved.language
    updateSnapshot("settings",next)
    var first=!settingsLoaded;settingsLoaded=true
    if(first)Qt.callLater(refresh)
  }
  onShellChanged: loadSettings()
  // 只合并用户编辑的字段，保留宿主布局属性，不直接读写任何配置文件。
  function saveSettings(values) {
    var next=Object.assign({},settings,values)
    next={serverURL:String(next.serverURL || "").trim(),language:next.language || "auto"}
    if(!validURL(next.serverURL) || ["auto","en","zh","ja"].indexOf(next.language)<0){tell("invalid_settings");return false}
    if(settings.serverURL===next.serverURL && settings.language===next.language){tell("done");return true}
    // 宿主配置快照稍后才回传；不能同步读回旧快照并误报保存失败。
    if(!shell || !shell.updateEntryInline("yumenaka.comigo",Object.assign({},hostEntry,{comigo:next}))){tell("settings_save_failed");return false}
    updateSnapshot("settings",next)
    tell("done")
    return true
  }
  // 主动断开停止请求并使在途响应失效；只有点击连接才恢复通信。
  function disconnectServer(){manuallyDisconnected=true;clearConnection();needsLogin=false}
  function connectServer(values){
    if(!saveSettings(values))return
    // 点击连接立即重试，取消旧请求，避免忙碌时按钮可点却没有响应。
    clearConnection()
    manuallyDisconnected=false
    refresh()
  }
  function setLanguage(value){saveSettings({language:value})}
  // 地址切换／退出时先使旧响应失效，再清空私有状态。
  function clearConnection() {
    generation++;queuedRequest=null;desiredExternalAccess=null
    timeout.stop()
    if(pendingHTTP){var old=pendingHTTP;pendingHTTP=null;old.signal(9);old.destroy()}
    selectedReadingIP="";connected=false;reachable=false;unsupportedServer=false
    info={};publicInfo={};traffic=null;serverConfig={};configFileStatus=null;notice="";lastError=""
  }
  function switchConnection() {
    if(sessionKey)sessions[sessionKey]={token:token}
    clearConnection();sessionKey=connectionKey
    token=(sessions[sessionKey] || {}).token || "";needsLogin=false
    if(settingsLoaded)Qt.callLater(refresh)
  }
  onConnectionKeyChanged: switchConnection()
  onActiveChanged: if(active && settingsLoaded)refresh()
  onPageChanged: if(active && (page==="config" || page==="service"))loadConfig()

  // 单个请求加有限排队，切换地址后旧回调不能更新当前界面。
  function request(method,path,body,callback,background) {
    if(manuallyDisconnected || !settingsLoaded || !endpoint)return false
    if(pendingHTTP){if(!background && httpBackground && !queuedRequest)queuedRequest=[method,path,body,callback,false];return false}
    // curl 配置从标准输入读取；地址、密码和令牌均不进入命令行或临时文件。
    var input="url = "+curlQuote(endpoint+path)+"\nrequest = "+curlQuote(method)+"\nheader = \"Content-Type: application/json\"\n"
    if(token && path!=="/api/info" && path!=="/api/login")input+="header = "+curlQuote("Authorization: Bearer "+token)+"\n"
    if(body!==null)input+="data-raw = "+curlQuote(JSON.stringify(body))+"\n"
    var proc=httpProcess.createObject(root,{input:input,callback:callback,requestGeneration:generation})
    pendingHTTP=proc;httpBackground=!!background
    timeout.restart();proc.running=true
    return true
  }
  function curlQuote(value){return '"'+String(value).replace(/\\/g,"\\\\").replace(/"/g,'\\"').replace(/\n/g,"\\n").replace(/\r/g,"\\r").replace(/\t/g,"\\t")+'"'}
  function finishRequest(proc,exitCode) {
    if(pendingHTTP!==proc)return
    timeout.stop();pendingHTTP=null
    var requestGeneration=proc.requestGeneration,callback=proc.callback,data={},status=0
    if(exitCode===0){
      var split=proc.output.lastIndexOf("\n")
      status=Number(proc.output.slice(split+1))
      // 无效 JSON 与重定向均按失败处理，401 即使没有 JSON 也必须清除认证状态。
      try{data=JSON.parse(proc.output.slice(0,split));if(!data || typeof data!=="object" || Array.isArray(data) || (status>=300 && status<400))throw new Error("invalid response")}catch(e){if(status!==401)status=0;data={}}
    }
    proc.destroy()
    if(requestGeneration!==generation)return
    if(status===401){token="";needsLogin=true;connected=false;info={};traffic=null;serverConfig={};configFileStatus=null}
    callback(status,data)
    if(queuedRequest){var next=queuedRequest;queuedRequest=null;Qt.callLater(function(){if(requestGeneration===root.generation)root.request(next[0],next[1],next[2],next[3],next[4])})}
  }
  Component {
    id:httpProcess
    Process {
      id:proc
      property string input:""
      property string output:""
      property var callback:null
      property int requestGeneration:0
      // -q 必须放在首位，忽略个人 curlrc；不跟随任何重定向，限制协议、时间和响应大小。
      command:["/usr/bin/curl","-q","--config","-","--silent","--globoff","--no-location","--proto","=http,https","--max-time","15","--max-filesize","1048576","--write-out","\n%{http_code}"]
      stdinEnabled:true
      onStarted:{write(input);input="";stdinEnabled=false}
      stdout:StdioCollector {waitForEnd:true;onStreamFinished:proc.output=text}
      onExited:function(exitCode){root.finishRequest(proc,exitCode)}
    }
  }
  // 同时覆盖 curl 无法启动的情况，不能让后台轮询永久占用请求槽。
  Timer {id:timeout;interval:16000;onTriggered:if(root.pendingHTTP){var proc=root.pendingHTTP;proc.signal(9);root.finishRequest(proc,-1)}}
  function refresh() {
    request("GET","/api/info",null,function(status,data){
      root.reachable=status===200;root.unsupportedServer=status===404 || (status===200 && !Model.supportedVersion(data.Version))
      if(status!==200){root.connected=false;root.info={};root.traffic=null;root.serverConfig={};root.configFileStatus=null;root.lastError=root.t(root.unsupportedServer ? "unsupported" : "offline");return}
      root.updateSnapshot("publicInfo",data)
      root.needsLogin=!!data.requiresAuth && !root.token
      if(root.needsLogin || root.unsupportedServer){root.connected=false;root.info={};root.traffic=null;root.serverConfig={};root.configFileStatus=null;return}
      Qt.callLater(function(){root.request("GET","/api/server",null,root.receiveServer,true)})
    },true)
  }
  function receiveServer(status,data) {
    connected=status===200 && !unsupportedServer && Array.isArray(data.localIPs) && data.localIPs.every(function(ip){return typeof ip==="string"})
    if(connected){updateSnapshot("info",data);updateSnapshot("traffic",data.traffic || null);lastError=""
      if(desiredExternalAccess!==null && data.externalAccess===desiredExternalAccess){desiredExternalAccess=null;tell("done")}
      if(page==="config" || page==="service")Qt.callLater(loadConfig)
    }else{info={};traffic=null;serverConfig={};configFileStatus=null;lastError=stateText}
  }
  function refreshTraffic(){if(connected && !busy)request("GET","/api/server/traffic",null,function(status,data){if(status===200)root.updateSnapshot("traffic",data);else root.traffic=null},true)}
  function loadConfig(){if(connected)request("GET","/api/configs",null,function(status,data){root.updateSnapshot("serverConfig",status===200 ? data : {});if(status===200){Qt.callLater(function(){root.request("GET","/api/configs/status",null,function(code,value){root.updateSnapshot("configFileStatus",code===200 ? value.current : null)},true)})}else root.configFileStatus=null},true)}
  function setExternalAccess(enabled) {
    if(!localConnection || busy || !connected || serverConfig.ReadOnlyMode!==false)return
    request("PATCH","/api/configs",{DisableLAN:!enabled},function(status){
      if(status===200){root.desiredExternalAccess=enabled;root.reconnectAttempts=0;root.connected=false}
      else root.tell(status===403 ? "config_locked" : "http_error")
    })
  }
  signal loginFinished(bool success,string errorKey)
  // 登录结果交给发起表单展示；传输错误不冒充账号密码错误。
  function login(username,password){
    if(busy || !settingsLoaded || !endpoint){loginFinished(false,"http_error");return}
    request("POST","/api/login",{username:username,password:password},function(status,data){
      var success=status===200 && typeof data.token==="string" && data.token!==""
      if(success){root.token=data.token;root.needsLogin=false;Qt.callLater(root.refresh)}
      root.loginFinished(success,success ? "" : status===401 ? "login_failed" : "http_error")
    })
  }
  function logout(){clearConnection();token="";sessions[sessionKey]={};needsLogin=true;Qt.callLater(refresh)}
  Timer {interval:500;running:root.desiredExternalAccess!==null;repeat:true;onTriggered:{if(root.pendingHTTP)return;if(++root.reconnectAttempts>30){root.desiredExternalAccess=null;root.tell("http_error")}else root.refresh()}}
  Timer {id:toastTimer;interval:3500;onTriggered:root.notice=""}
  Timer {interval:30000;running:root.settingsLoaded && !root.manuallyDisconnected;repeat:true;onTriggered:if(!root.busy)root.refresh()}
  Timer {interval:2000;running:root.active && root.connected;repeat:true;onTriggered:{if(root.busy || root.pendingHTTP)return;if(root.page==="config" || root.page==="service")root.refresh();else root.refreshTraffic()}}
}
