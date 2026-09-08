import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model
import "I18n.js" as I18n

// 单例持有连接和会话；多个屏幕共用轮询，不在每个图标中重复查询。
Item {
  id: root
  property var manifest: null
  readonly property string runner: manifest && manifest.__sourceDir ? String(manifest.__sourceDir) + "/bin/comigo-ctl" : decodeURIComponent(Qt.resolvedUrl("bin/comigo-ctl").toString().replace(/^file:\/\//, ""))
  readonly property var defaultSettings: ({serverURL:"http://127.0.0.1:1234/", remoteURL:"", cliPath:"", libraryDir:"", language:"auto", autoStart:false})
  property var settings: Object.assign({},defaultSettings)
  property int autoStartAttempts: 0
  property bool autoStartDone: false
  property bool settingsLoaded: false
  property bool active: false
  property string page: "home"
  property bool connected: false
  property bool unsupportedServer: false
  property bool needsLogin: false
  property var info: ({})
  property var traffic: null
  property var serverConfig: ({})
  property var configFileStatus: null
  property bool localChecked: false
  property var localInfo: ({installed:false, active:"unknown", desktop:false})
  property var updateInfo: ({state:"unchecked"})
  property string token: ""
  property string notice: ""
  property string lastError: ""
  property var pendingHTTP: null
  property string httpInput: ""
  property bool httpBackground: false
  property var queuedRequest: null
  property string mode: "local"
  readonly property bool remote: mode === "remote"
  readonly property string serviceName: t(remote ? "remote_service" : "local_service")
  readonly property string connectionKey: mode + ":" + endpoint
  property string sessionKey: ""
  property var sessions: ({})
  property int generation: 0
  property int requestGeneration: 0
  property string localAction: ""
  property string localInput: ""
  property bool localPending: false
  property var queuedLocal: null
  property var desiredExternalAccess: null
  property int reconnectAttempts: 0
  readonly property string endpoint: String(remote ? settings.remoteURL || "" : settings.serverURL || "http://127.0.0.1:1234/").replace(/\/+$/, "")
  readonly property string language: settings.language === "auto" ? Qt.locale().name : settings.language || "en"
  readonly property bool busy: (pendingHTTP !== null && !httpBackground) || queuedRequest !== null || queuedLocal !== null || (localPending && localAction !== "status") || desiredExternalAccess !== null
  readonly property string version: info.Version || (!remote ? localInfo.version : "") || "—"
  property string selectedReadingIP: ""
  readonly property var readingIPs: remote || info.externalAccess===false ? [] : (info.localIPs || []).filter(function(ip, index, ips) {return ips.indexOf(ip)===index})
  readonly property string defaultReadingURL: remote ? (endpoint ? endpoint + "/" : "") : info.readingURL || endpoint + "/"
  readonly property string readingURL: !remote && selectedReadingIP && readingIPs.indexOf(selectedReadingIP)>=0 ? Model.withHost(defaultReadingURL,selectedReadingIP) : defaultReadingURL
  readonly property string currentReadingIP: Model.urlHost(readingURL)
  onReadingIPsChanged: if(readingIPs.indexOf(selectedReadingIP)<0)selectedReadingIP=""
  // 首次沿用服务返回的出口地址，用户选择后跨轮询保留，网卡消失则回退。
  function cycleReadingIP(direction) {
    if(remote || readingIPs.length<2)return
    var index=readingIPs.indexOf(currentReadingIP)
    selectedReadingIP=readingIPs[(index<0 ? (direction>0 ? 0 : readingIPs.length-1) : index+direction+readingIPs.length)%readingIPs.length]
  }
  readonly property string browserURL: remote || selectedReadingIP ? readingURL : info.localBrowserURL || endpoint + "/"
  readonly property string stateText: needsLogin ? t("needs_login") : connected ? t("running") : unsupportedServer ? t("unsupported") : remote ? t(endpoint ? "offline" : "remote_setup") : !localInfo.installed ? t("missing_cli") : localInfo.active === "inactive" ? t("stopped") : t("offline")
  function updateSnapshot(name, value) {
    var next=Model.reconcile(root[name],value)
    if(root[name]!==next)root[name]=next
  }
  function t(key) { return I18n.text(key, language) }
  function bytes(value) { return Model.bytes(value) }
  function tell(key) { notice = t(key); toastTimer.restart() }
  function copy(value) { Quickshell.clipboardText = String(value); tell("copied") }
  function browse(url) { if (/^https?:\/\//.test(url)) Qt.openUrlExternally(url) }
  function upgradeCommand() { return Model.shellQuote(localInfo.cliPath || "comi") + " --upgrade" }

  // 用户配置只保存非敏感字段，登录令牌从不写盘。
  function saveSettings(values) {
    if (busy) return
    var next = {serverURL:String(values.serverURL || "").trim(), remoteURL:String(values.remoteURL || "").trim(), cliPath:String(values.cliPath || "").trim(), libraryDir:String(values.libraryDir || "").trim(), language:String(values.language || "auto"), autoStart:values.autoStart===true}
    if (!validURL(next.serverURL) || !/^https?:\/\/(127\.0\.0\.1|localhost|\[::1\])(:[0-9]+)?(\/|$)/.test(next.serverURL) || (next.remoteURL && !validURL(next.remoteURL)) || ["auto","en","zh","ja"].indexOf(next.language)<0) { tell("invalid_settings"); return }
    for (var key in next) if (/[\r\n\x00]/.test(next[key])) { tell("invalid_settings"); return }
    localInput = JSON.stringify(next)
    runLocal("save-settings", [])
  }
  function validURL(value) { return /^https?:\/\/[^\s?#@]+(?:\/[^\s?#]*)?$/.test(value) }
  function setMode(value) { if (!busy && (value === "local" || value === "remote")) mode=value }
  // 请求代次隔离模式切换和退出登录，旧响应不得恢复已清空的状态。
  function clearConnection() {
    selectedReadingIP=""
    generation++; queuedRequest=null; desiredExternalAccess=null
    connected=false; unsupportedServer=false; info={}; traffic=null; serverConfig={}; configFileStatus=null; updateInfo={state:"unchecked"}
    notice=""; lastError=""
  }
  function switchConnection() {
    if(sessionKey) sessions[sessionKey]={token:token,needsLogin:needsLogin}
    clearConnection()
    sessionKey=connectionKey
    var session=sessions[sessionKey] || {}
    token=session.token || ""; needsLogin=!!session.needsLogin
    if(settingsLoaded)Qt.callLater(root.refresh)
  }
  function setLanguage(language) { var next = Object.assign({}, settings); next.language = language; saveSettings(next) }
  FileView {
    id: settingsFile
    watchChanges:true
    onFileChanged:reload()
    path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/omarchy-comigo/settings.json"
    onLoaded: {
      var previous=root.settings, first=!root.settingsLoaded
      try { var parsed = JSON.parse(text()); if (parsed.serverURL) {
        var next=Object.assign({},root.defaultSettings)
        for(var key in next)if(parsed[key]!==undefined)next[key]=parsed[key]
        root.updateSnapshot("settings",next)
      } }
      catch (e) { root.lastError = root.t("invalid_settings") }
      root.settingsLoaded = true; if(first || previous!==root.settings)Qt.callLater(root.refresh)
    }
    onLoadFailed: { root.settingsLoaded = true; Qt.callLater(root.refresh) }
  }
  onConnectionKeyChanged: switchConnection()
  onActiveChanged: if (active && settingsLoaded) refresh()
  onPageChanged: if (active && page === "config" && connected) loadConfig()

  function request(method, path, body, callback, background) {
    if (!settingsLoaded || !endpoint) return false
    if (pendingHTTP) {
      if (!background && httpBackground && !queuedRequest) {queuedRequest=[method,path,body,callback];return true}
      return false
    }
    httpBackground=!!background
    requestGeneration=generation
    pendingHTTP = callback
    httpInput = token + "\n" + (body === null ? "" : JSON.stringify(body))
    httpProc.command = ["bash", runner, "request", method, endpoint, path]
    httpProc.running = true
    return true
  }
  function finishHTTP(raw, code) {
    var callback = pendingHTTP, stale=requestGeneration!==generation
    pendingHTTP = null
    httpBackground=false
    var end = raw.lastIndexOf("\n"), status = end < 0 ? 0 : Number(raw.slice(end + 1))
    var data = {}
    try { data = JSON.parse(raw.slice(0, end)) } catch (e) {}
    if (code !== 0 && status !== 401) status = 0
    if (stale) Qt.callLater(root.refresh)
    else {
      if (status === 401) { token=""; needsLogin=true; connected=false; info={}; traffic=null; serverConfig={};configFileStatus=null }
      if (callback) callback(status, data)
    }
    if (queuedRequest) {var next=queuedRequest;queuedRequest=null;request(next[0],next[1],next[2],next[3],false)}
  }
  function refresh(includeLocal) {
    if (!settingsLoaded) return
    if (!remote && includeLocal!==false && !localPending) runLocal("status", [settings.cliPath || "",endpoint+"/"])
    if (needsLogin) return
    request("GET", "/api/server", null, function(status, data) {
      root.receiveServer(status, data)
    },true)
  }
  function receiveServer(status, data) {
    // 按 v1.3.5 服务协议校验版本和接口可用性。
    root.unsupportedServer = status === 404 || (status === 200 && (!data || !Model.supportedVersion(data.Version)))
    root.connected = status === 200 && !root.unsupportedServer
    if (root.connected) {
      root.updateSnapshot("info",data); root.updateSnapshot("traffic",data.traffic || null); root.lastError = ""
      if (root.desiredExternalAccess !== null && data.externalAccess === root.desiredExternalAccess) {root.desiredExternalAccess=null;root.tell("done")}
      if (data.update) root.updateSnapshot("updateInfo",data.update)
      if (root.page === "config") Qt.callLater(root.loadConfig)
    } else { root.info={}; root.traffic=null; root.lastError = root.t(status === 401 ? "needs_login" : root.unsupportedServer ? "unsupported" : "offline") }
  }
  function refreshTraffic() {
    if (!connected || !traffic || busy) return
    request("GET", "/api/server/traffic", null, function(status,data) {
      if (status===200) root.updateSnapshot("traffic",data)
      else { root.traffic=null; if (status!==404) {root.connected=false;root.lastError=root.t("offline")} }
    },true)
  }
  // 更改监听范围后等待 HTTP 服务重新就绪，再更新开关和阅读地址。
  function setExternalAccess(enabled) {
    if (remote || busy || !connected) return
    request("PATCH", "/api/configs", {DisableLAN:!enabled}, function(status,data) {
      if(status===200) {root.desiredExternalAccess=enabled;root.reconnectAttempts=0;root.connected=false;root.info={};root.serverConfig={};root.configFileStatus=null}
      else root.tell(status===403 ? "config_locked" : "http_error")
    })
  }
  Timer {
    interval:500;running:root.desiredExternalAccess!==null;repeat:true
    onTriggered:{
      if(root.pendingHTTP)return
      if(++root.reconnectAttempts>30){root.desiredExternalAccess=null;root.tell("http_error");return}
      root.refresh()
    }
  }
  function loadConfig() {
    if (!connected) return
    request("GET", "/api/configs", null, function(status,data) {
      if(status===200) {root.updateSnapshot("serverConfig",data);Qt.callLater(root.loadConfigFileStatus)}
    },true)
  }
  function loadConfigFileStatus() {
    if(!connected)return
    request("GET","/api/configs/status",null,function(status,data){root.updateSnapshot("configFileStatus",status===200 && data.current ? data.current : null)},true)
  }
  function login(username, password) {
    request("POST", "/api/login", {username:username,password:password}, function(status,data) {
      if(status===200 && data.token) {root.token=data.token;root.needsLogin=false;root.lastError="";Qt.callLater(root.refresh)}
      else root.tell("needs_login")
    })
  }
  function logout() { clearConnection();token="";needsLogin=true }
  function checkUpdate() {
    if (connected) request("GET", "/api/server/update", null, function(status,data) {root.updateInfo=status===200 ? data : {state:"error"};if(status!==200)root.tell("http_error")})
    else if (!remote) runLocal("check-update", [settings.cliPath || ""])
  }
  function firewall(action) {
    if(remote || busy)return
    runLocal("firewall-"+action,[endpoint+"/"])
  }
  function control(action) {
    if (remote || busy) return
    autoStartDone=true
    runLocal(action,[endpoint + "/",settings.cliPath || "",settings.libraryDir || ""])
  }
  function runLocal(action, args) {
    if (remote && action!=="save-settings") return
    if (localPending) {
      if(localAction==="status" && action!=="status" && !queuedLocal){queuedLocal={action:action,args:args,input:localInput};localInput=""}
      return
    }
    localAction=action;localPending=true
    localProc.command=["bash",runner,action].concat(args)
    localProc.running=true
  }
  function finishLocal(raw, code) {
    var action=localAction, data={}
    localPending=false
    try {data=JSON.parse(raw)} catch(e){data={error:"command_failed"}}
    if(action==="autostart" && ((!data.error && code===0) || data.error==="autostart_exhausted"))autoStartDone=true
    if(data.error || code!==0) {tell(data.error || "command_failed"); drainLocal();return}
    if(action==="status") {
      updateSnapshot("localInfo",data);localChecked=true
    }
    else if(action==="check-update") updateSnapshot("updateInfo",data)
    else {
      if(action==="save-settings") settingsFile.reload()
      if(action==="install") {var next=Object.assign({},settings);next.cliPath=data.cliPath;localInput=JSON.stringify(next);runLocal("save-settings",[])}
      tell("done");afterCommand.restart()
    }
    drainLocal()
  }
  function drainLocal() {
    if(!localPending && queuedLocal){var next=queuedLocal;queuedLocal=null;localInput=next.input;runLocal(next.action,next.args)}
  }
  // 只在本机模式加载后尝试，关闭选项或手动控制立即取消后续重试。
  Timer {
    interval:10000;repeat:true
    running:root.settingsLoaded && root.settings.autoStart===true && !root.remote && !root.autoStartDone && root.autoStartAttempts<3 && !root.localPending
    onTriggered:{
      if(root.busy || root.localPending)return
      root.autoStartAttempts++
      root.runLocal("autostart",[root.endpoint+"/",root.settings.cliPath || "",root.settings.libraryDir || ""])
    }
  }
  Timer { id: afterCommand; interval: 100; onTriggered: root.refresh() }
  Timer { id: toastTimer; interval: 3500; onTriggered: root.notice="" }
  Timer { interval: 30000; running: root.settingsLoaded; repeat: true; onTriggered: if(!root.busy)root.refresh() }
  Timer { interval: 2000; running: root.active && root.connected; repeat: true; onTriggered: {if(root.busy || root.pendingHTTP)return;if(root.page==="config")root.refresh(false);else root.refreshTraffic()} }
  Process {
    id: httpProc
    stdinEnabled: true
    onStarted: {write(root.httpInput);root.httpInput="";stdinEnabled=false}
    stdout: StdioCollector { id:httpOutput; waitForEnd:true }
    onExited: function(code) {stdinEnabled=true;Qt.callLater(function(){root.finishHTTP(httpOutput.text,code)})}
  }
  Process {
    id: localProc
    stdinEnabled:true
    onStarted: {write(root.localInput);root.localInput="";stdinEnabled=false}
    stdout: StdioCollector {id:localOutput;waitForEnd:true}
    onExited: function(code){stdinEnabled=true;Qt.callLater(function(){root.finishLocal(localOutput.text,code)})}
  }
}
