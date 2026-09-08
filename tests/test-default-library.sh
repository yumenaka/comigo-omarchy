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
trap 'ctl stop "$endpoint" >/dev/null || true' EXIT
cd -- "$HOME"
ctl start "$endpoint" "$tmp/bin/comi" ''
[[ ! -e "$HOME/Documents" ]]
[[ $(ctl status "$tmp/bin/comi") == *'"active":"active"'* ]]
mkdir -p "$tmp/books"
ctl restart "$endpoint" "$tmp/bin/comi" "$tmp/books"
curl -q --noproxy '*' --silent --fail "${endpoint}healthz" >/dev/null
ctl stop "$endpoint"
[[ $(ctl status "$tmp/bin/comi") == *'"active":"inactive"'* ]]
echo 'Comigo default library startup passed'
