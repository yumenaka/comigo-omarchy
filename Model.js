// 界面数据格式化与快照复用。
function bytes(value) {
  if (typeof value !== "number" || !isFinite(value)) return "—"
  var units = ["B", "KiB", "MiB", "GiB", "TiB"], i = 0
  while (value >= 1024 && i < units.length - 1) { value /= 1024; i++ }
  return value.toFixed(i ? 1 : 0) + " " + units[i]
}
function shellQuote(value) { return "'" + String(value).replace(/'/g, "'\\''") + "'" }

// 未变化的数据沿用原对象，避免列表和绑定在轮询时重复重建。
function reconcile(previous, next) {
  if (previous === next) return previous
  if (!previous || !next || typeof previous !== "object" || typeof next !== "object") return next
  if (Array.isArray(previous) !== Array.isArray(next)) return next
  var keys = Object.keys(next), unchanged = keys.length === Object.keys(previous).length
  for (var i=0;i<keys.length;i++) {
    var key=keys[i]
    next[key]=reconcile(previous[key],next[key])
    if (!Object.prototype.hasOwnProperty.call(previous,key) || previous[key]!==next[key]) unchanged=false
  }
  return unchanged ? previous : next
}

// 最低支持正式版 v1.3.5；构建元数据不影响版本门槛。
function supportedVersion(value) {
  var match = /^v?(\d+)\.(\d+)\.(\d+)(?:\+[0-9A-Za-z.-]+)?$/.exec(String(value || ""))
  if (!match) return false
  var major = Number(match[1]), minor = Number(match[2]), patch = Number(match[3])
  return major > 1 || (major === 1 && (minor > 3 || (minor === 3 && patch >= 5)))
}

// 只替换 URL 主机，保留协议、端口、路径及查询；IPv6 使用方括号。
function urlHost(url) {
  var match = /^https?:\/\/(\[[^\]]+\]|[^/:?#]+)/.exec(url)
  return match ? match[1].replace(/^\[|\]$/g, "") : ""
}
function withHost(url, host) {
  return url.replace(/^(https?:\/\/)(\[[^\]]+\]|[^/:?#]+)/, function(_, scheme) {
    return scheme + (host.indexOf(":") >= 0 ? "[" + host + "]" : host)
  })
}
