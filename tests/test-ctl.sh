#!/usr/bin/env bash
# Bash 替身验证进程边界。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-ctl-test.XXXXXX")
mkdir -p "$tmp/bin" "$tmp/config" "$tmp/books"
export XDG_CONFIG_HOME="$tmp/config" PATH="$tmp/bin:$PATH"
cat > "$tmp/bin/comi" <<'CLI'
#!/usr/bin/env bash
case "$*" in
  --version) echo 'Comigo v1.2.3';;
  --help) echo '  comi desktop Machine-readable desktop integration: info';;
  *) exit 99;;
esac
CLI
cat > "$tmp/bin/curl" <<'CURL'
#!/usr/bin/env bash
# 令牌和密码不得出现在 argv，分别从 stdin 和 fd 3 获取。
for arg in "$@"; do [[ "$arg" != *test-token* && "$arg" != *test-password* ]] || exit 99; done
headers=""; IFS= read -r -d '' headers || true
[[ "$headers" == *'Authorization: Bearer test-token'* ]] || exit 98
body=""; IFS= read -r -d '' body <&3 || true
[[ "$body" == *test-password* ]] || exit 97
printf '{"ok":true}\n200'
CURL
chmod +x "$tmp/bin/"*
status=$(bash "$root/bin/comigo-ctl" status)
[[ "$status" == *'"installed":true'* && "$status" == *'"desktop":true'* ]]
result=$(printf 'test-token\n{"password":"test-password"}' | bash "$root/bin/comigo-ctl" request POST http://localhost:1234 /api/login)
[[ "$result" == *$'\n200' ]]
# 伪造记录即便指向存活 PID，启动时间不匹配时也绝不能发送信号。
export XDG_RUNTIME_DIR="$tmp/runtime" XDG_STATE_HOME="$tmp/state"
mkdir -p "$XDG_RUNTIME_DIR/omarchy-comigo"
sleep 60 &
foreign_pid=$!
trap 'kill "$foreign_pid" 2>/dev/null || true' EXIT
printf '%s 0\n' "$foreign_pid" > "$XDG_RUNTIME_DIR/omarchy-comigo/process"
bash "$root/bin/comigo-ctl" stop http://localhost:1234/ >/dev/null
kill -0 "$foreign_pid"
if bash "$root/bin/comigo-ctl" start http://example.com/ "$tmp/bin/comi" "$tmp/books" > "$tmp/out"; then exit 1; fi
[[ $(< "$tmp/out") == *local_url_required* ]]
printf '{"serverURL":"http://localhost:1234/","language":"ja"}' | bash "$root/bin/comigo-ctl" save-settings >/dev/null
[[ $(< "$XDG_CONFIG_HOME/omarchy-comigo/settings.json") == *'"language":"ja"'* ]]
# 状态查询仍能识别 CLI 的桌面协议能力。
printf '#!/usr/bin/env bash\ncase "$*" in --version) echo "Comigo v1.0.0";; --help) echo usage;; *) exit 99;; esac\n' > "$tmp/bin/comi"
[[ $(bash "$root/bin/comigo-ctl" status) == *'"desktop":false'* ]]
if bash "$root/bin/comigo-ctl" check-update > "$tmp/out"; then exit 1; fi
[[ $(< "$tmp/out") == *unknown_action* ]]

# 状态查询不提供默认书库，书库规则由 Comigo 管理。
[[ "$status" != *'"defaultLibrary":'* ]]
# 失败预算跨控制器调用保存；手动停止后即使插件重载也不再自动启动。
rm -f "$XDG_RUNTIME_DIR/omarchy-comigo/autostart-done"
for expected in 1 2 3; do
  if bash "$root/bin/comigo-ctl" autostart http://localhost:1234/ "$tmp/missing" "$tmp/books" > "$tmp/out"; then exit 1; fi
  [[ $(< "$tmp/out") == *missing_cli* ]]
  [[ $(< "$XDG_RUNTIME_DIR/omarchy-comigo/autostart-attempts") == "$expected" ]]
done
if bash "$root/bin/comigo-ctl" autostart http://localhost:1234/ "$tmp/missing" "$tmp/books" > "$tmp/out"; then exit 1; fi
[[ $(< "$tmp/out") == *autostart_exhausted* ]]
bash "$root/bin/comigo-ctl" stop http://localhost:1234/ >/dev/null
[[ $(bash "$root/bin/comigo-ctl" autostart http://localhost:1234/ "$tmp/missing") == *'"ok":true'* ]]
echo 'Bash controller tests passed'
