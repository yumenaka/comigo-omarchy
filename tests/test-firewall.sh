#!/usr/bin/env bash
# 用隔离规则文件与授权替身验证放行范围和规则归属。
set -euo pipefail
root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/comigo-firewall-test.XXXXXX")
mkdir "$tmp/bin"
export FIREWALL_TEST="$tmp" PATH="$tmp/bin:$PATH"
source_code=$(< "$root/bin/comigo-firewall")
source_code=${source_code//\/etc\/ufw\/ufw.conf/$tmp/ufw.conf}
source_code=${source_code//\/etc\/ufw\/user.rules/$tmp/user.rules}
printf '%s\n' "$source_code" > "$tmp/firewall"
printf 'ENABLED=yes\n' > "$tmp/ufw.conf"
: > "$tmp/user.rules"
cat > "$tmp/bin/ip" <<'BASH'
#!/usr/bin/env bash
if [[ "$*" == '-4 route show default' ]]; then echo 'default via 192.168.8.1 dev wlan0';else echo "${TEST_SUBNET:-192.168.8.0/24} dev wlan0 proto kernel";fi
BASH
cat > "$tmp/bin/pkexec" <<'BASH'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$FIREWALL_TEST/calls"
exit "${TEST_AUTH_EXIT:-0}"
BASH
printf '#!/usr/bin/env bash\nexit 0\n' > "$tmp/bin/ufw"
chmod +x "$tmp/bin/"*
ctl(){ bash "$tmp/firewall" "$@"; }
status=$(ctl status http://localhost:3456/)
[[ "$status" == *'"subnet":"192.168.8.0/24"'* && "$status" == *'"configured":false'* ]]
ctl open http://localhost:3456/ >/dev/null
[[ $(< "$tmp/calls") == '/usr/bin/ufw allow in on wlan0 proto tcp from 192.168.8.0/24 to any port 3456 comment omarchy-comigo' ]]
: > "$tmp/calls"
printf '### tuple ### allow tcp 3456 0.0.0.0/0 any 192.168.8.0/24 in_wlan0\n' > "$tmp/user.rules"
ctl open http://localhost:3456/ >/dev/null
[[ ! -s "$tmp/calls" ]]
printf '### tuple ### allow tcp 1234 0.0.0.0/0 any 10.2.0.0/16 in_eth0 comment=6f6d61726368792d636f6d69676f\n' >> "$tmp/user.rules"
ctl close http://localhost:3456/ >/dev/null
[[ $(< "$tmp/calls") == '/usr/bin/ufw --force delete allow in on eth0 proto tcp from 10.2.0.0/16 to any port 1234 comment omarchy-comigo' ]]
if ctl open http://example.com:1234/ > "$tmp/error"; then exit 1;fi
[[ $(< "$tmp/error") == *local_url_required* ]]
if ctl open http://localhost:65536/ > "$tmp/error";then exit 1;fi
[[ $(< "$tmp/error") == *invalid_port* ]]
if TEST_SUBNET=0.0.0.0/0 ctl open http://localhost:3456/ > "$tmp/error";then exit 1;fi
[[ $(< "$tmp/error") == *lan_not_found* ]]
: > "$tmp/user.rules"
if TEST_AUTH_EXIT=1 ctl open http://localhost:3456/ > "$tmp/error";then exit 1;fi
[[ $(< "$tmp/error") == *firewall_failed* ]]
echo 'Scoped UFW rules and ownership tests passed'
