#!/usr/bin/env bash
# 在隔离 HOME 下验证未配置书库时的完整启动路径。
set -euo pipefail
: "${COMIGO_TEST_CLI:?Set COMIGO_TEST_CLI to the Comigo executable}"
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
binary=$(realpath -- "$COMIGO_TEST_CLI")
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-default-library.XXXXXX")
export HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" XDG_STATE_HOME="$tmp/state" XDG_RUNTIME_DIR="$tmp/runtime"
mkdir -p "$HOME" "$tmp/bin"
test_port=$((30000+RANDOM%20000))
while (exec 3<>"/dev/tcp/127.0.0.1/$test_port") 2>/dev/null; do test_port=$((test_port+1)); done
# 仅覆盖测试端口和监听范围，书库参数完整传给真实 CLI。
printf '#!/usr/bin/env bash\nexec %q --port %q --local "$@"\n' "$binary" "$test_port" > "$tmp/bin/comi"
chmod +x "$tmp/bin/comi"
endpoint="http://127.0.0.1:$test_port/"
ctl() { bash "$root/bin/comigo-ctl" "$@"; }
trap 'ctl stop "$endpoint" >/dev/null || true; rm -rf -- "$tmp"' EXIT
cd -- "$HOME"
# 等待真实扫描完成，检查运行配置中的书库而非仅检查服务存活。
assert_library() {
  local expected="$1"
  for ((attempt=0;attempt<50;attempt++)); do
    if curl -q --noproxy '*' --silent --fail "${endpoint}api/configs" | jq -e --arg path "$expected" '.StoreUrls == [$path]' >/dev/null; then return; fi
    sleep 0.1
  done
  echo "Unexpected library: $expected" >&2
  return 1
}
ctl start "$endpoint" "$tmp/bin/comi" ''
assert_library "$HOME"
[[ ! -e "$HOME/Pictures" && ! -e "$HOME/Documents" && ! -e "$HOME/Downloads" ]]
ctl stop "$endpoint"
# 三个目录同时存在时先用图片；逐一移除，验证候补顺序。
mkdir -p "$HOME/Pictures" "$HOME/Documents" "$HOME/Downloads"
for name in Pictures Documents Downloads; do
  ctl start "$endpoint" "$tmp/bin/comi" ''
  assert_library "$HOME/$name"
  ctl stop "$endpoint"
  rmdir "$HOME/$name"
done
ctl start "$endpoint" "$tmp/bin/comi" ''
assert_library "$HOME"
[[ ! -e "$HOME/Pictures" && ! -e "$HOME/Documents" && ! -e "$HOME/Downloads" ]]
# 已有配置文件即使没配置书库，也沿用工作目录。
mkdir -p "$HOME/Pictures" "$HOME/.config/comigo" "$tmp/books"
printf 'StoreUrls = []\n' > "$HOME/.config/comigo/config.toml"
ctl restart "$endpoint" "$tmp/bin/comi" ''
assert_library "$HOME"
ctl restart "$endpoint" "$tmp/bin/comi" "$tmp/books"
assert_library "$tmp/books"
ctl stop "$endpoint"
[[ $(ctl status "$tmp/bin/comi") == *'"active":"inactive"'* ]]
echo 'Comigo default library startup passed'
