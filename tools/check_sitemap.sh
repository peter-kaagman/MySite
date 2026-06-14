#!/usr/bin/env bash
# check_sitemap.sh - Download sitemap.xml en check of alle URLs bereikbaar zijn.
# Gebruik: ./tools/check_sitemap.sh [sitemap-url]
# Standaard: https://mysite.prjv.nl/sitemap.xml

set -euo pipefail

SITEMAP_URL="${1:-https://mysite.prjv.nl/sitemap.xml}"
PASS=0
FAIL=0
ERRORS=()

echo "Sitemap ophalen: $SITEMAP_URL"
echo ""

SITEMAP=$(curl -s --max-time 15 "$SITEMAP_URL") || {
  echo "FOUT: Kon sitemap niet ophalen van $SITEMAP_URL"
  exit 1
}

URLS=$(echo "$SITEMAP" | grep -oP '(?<=<loc>)[^<]+')

if [[ -z "$URLS" ]]; then
  echo "FOUT: Geen <loc> gevonden in sitemap."
  exit 1
fi

TOTAL=$(echo "$URLS" | wc -l)
echo "Gevonden: $TOTAL URL's"
echo "----------------------------------------"

while IFS= read -r url; do
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")
  if [[ "$HTTP_CODE" =~ ^(200|301|302)$ ]]; then
    echo "OK  [$HTTP_CODE] $url"
    PASS=$((PASS + 1))
  else
    echo "NOK [$HTTP_CODE] $url"
    ERRORS+=("[$HTTP_CODE] $url")
    FAIL=$((FAIL + 1))
  fi
done <<< "$URLS"

echo ""
echo "========================================"
echo "Resultaat: $PASS OK, $FAIL MISLUKT van $TOTAL"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "Mislukte URL's:"
  for err in "${ERRORS[@]}"; do
    echo "  $err"
  done
  exit 1
fi

exit 0
