#!/usr/bin/env bash
# Opens Flutter web in Brave as a phone-sized app window (no URL bar).
# Used via CHROME_EXECUTABLE — see .vscode/launch.json and app/README.md.
BRAVE="${BRAVE_BIN:-/usr/bin/brave-browser}"
ARGS=()
APP_URL=""

for arg in "$@"; do
  if [[ "$arg" =~ ^https?:// ]]; then
    APP_URL="$arg"
  else
    ARGS+=("$arg")
  fi
done

if [[ -n "$APP_URL" ]]; then
  # 412x892 ≈ Pixel 7 viewport
  exec "$BRAVE" "${ARGS[@]}" "--app=$APP_URL" "--window-size=412,892"
else
  exec "$BRAVE" "$@"
fi
