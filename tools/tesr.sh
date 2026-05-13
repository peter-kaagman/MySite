#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-happyminds.nl}"
SCHEME="${2:-https}"
WP_LOGIN_BURST="${3:-40}"
XMLRPC_BURST="${4:-30}"
CONCURRENCY="${5:-1}"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is niet gevonden in PATH"
  exit 1
fi

base_url="${SCHEME}://${HOST}"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "== CrowdSec traffic test =="
echo "target=${base_url}"
echo "wp_login_burst=${WP_LOGIN_BURST}"
echo "xmlrpc_burst=${XMLRPC_BURST}"
echo "concurrency=${CONCURRENCY}"
echo

run_burst() {
  local label="$1"
  local method="$2"
  local url="$3"
  local data="$4"
  local count="$5"

  echo "-- ${label} (${count} requests)"

  seq "$count" | xargs -n1 -P "$CONCURRENCY" bash -c '
    method="$1"
    url="$2"
    data="$3"
    if [[ "$method" == "POST" ]]; then
      curl -k -sS -o /dev/null -w "%{http_code}\n" -A "crowdsec-test/1.0" -X POST --data "$data" "$url" || echo ERR
    else
      curl -k -sS -o /dev/null -w "%{http_code}\n" -A "crowdsec-test/1.0" "$url" || echo ERR
    fi
  ' _ "$method" "$url" "$data" >> "$tmpdir/status_codes.txt"
}

# Baseline (lijkt normaal verkeer)
run_burst "baseline-home" "GET" "${base_url}/" "" 5

# Verdacht verkeer: login brute-force patroon
run_burst "wp-login-get" "GET" "${base_url}/wp-login.php" "" "$WP_LOGIN_BURST"
run_burst "wp-login-post" "POST" "${base_url}/wp-login.php" "log=invalid&pwd=invalid&wp-submit=Log+In" "$WP_LOGIN_BURST"

# Verdacht verkeer: xmlrpc abuse patroon
run_burst "xmlrpc-post" "POST" "${base_url}/xmlrpc.php" "<?xml version='1.0'?><methodCall><methodName>system.listMethods</methodName><params></params></methodCall>" "$XMLRPC_BURST"

# Probe paden (worden vaak door scanners geraakt)
run_burst "probe-env" "GET" "${base_url}/.env" "" 5
run_burst "probe-admin" "GET" "${base_url}/wp-admin/install.php" "" 5

echo
echo "== HTTP status verdeling =="
sort "$tmpdir/status_codes.txt" | uniq -c | sort -nr

echo
echo "Klaar. Controleer nu op de server:"
echo "  cd /home/pkn/cluster/crowdsec"
echo "  ./52-crowdsec-summary.sh"
echo "  ./51-observe-crowdsec-state.sh"
