#!/usr/bin/env bash
# Inajenga web app ya U'r Invente pamoja na kurasa za kisheria na ukurasa wa RSVP (build/web).
#
# Vigezo (environment variables), vyote si lazima:
#   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY  bila hivi, web app inajengwa kama demo (DEMO=true)
#   BASE_HREF        mf. /mwaliko-app/ kwa GitHub Pages, au / kwa domain yako (default /)
#   WEB_BASE_URL     anwani kamili ya web app, mf. https://app.urinvente.co.tz
#   SUPPORT_EMAIL, SUPPORT_PHONE  mawasiliano ya msaada kwenye app na kwenye kurasa za kisheria
set -euo pipefail
cd "$(dirname "$0")/.."

BASE_HREF="${BASE_HREF:-/}"
WEB_BASE_URL="${WEB_BASE_URL:-}"
WEB_BASE_URL="${WEB_BASE_URL%/}"
SUPPORT_EMAIL="${SUPPORT_EMAIL:-}"
SUPPORT_PHONE="${SUPPORT_PHONE:-}"

python3 tool/dart_defines.py build/defines.json
flutter build web --release --base-href "$BASE_HREF" --no-web-resources-cdn --pwa-strategy=none \
  --dart-define-from-file=build/defines.json

# Mawasiliano kwenye kurasa za kisheria
contact=""
[[ -n "$SUPPORT_EMAIL" ]] && contact="<a href=\"mailto:$SUPPORT_EMAIL\">$SUPPORT_EMAIL</a>"
[[ -n "$SUPPORT_PHONE" ]] && contact="${contact:+$contact au }<a href=\"tel:${SUPPORT_PHONE// /}\">$SUPPORT_PHONE</a>"
[[ -z "$contact" ]] && contact="sehemu ya Msaada ndani ya app"
for page in privacy terms delete-account; do
  CONTACT="$contact" python3 - "build/web/$page.html" <<'PY'
import os, sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read().replace("__SUPPORT_CONTACT__", os.environ["CONTACT"])
open(path, "w", encoding="utf-8").write(text)
PY
done

# Ukurasa wa RSVP kwa waalikwa: <web app>/rsvp/?t=TOKEN
mkdir -p build/web/rsvp
cp rsvp_web/index.html build/web/rsvp/index.html
cat > build/web/rsvp/config.js <<JS
window.MWALIKO_CONFIG = {
  supabaseUrl: "${SUPABASE_URL:-}",
  supabaseKey: "${SUPABASE_PUBLISHABLE_KEY:-}",
};
JS

# GitHub Pages: bila faili hili, folda zinazoanza na "_" hazitumwi
touch build/web/.nojekyll
echo "Tayari: build/web"
