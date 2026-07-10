#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="SkillsBar"
BUNDLE_ID="local.jscraik.skillsbar"
BUILD_ROOT="${SKILLSBAR_BUILD_ROOT:-$HOME/.codex/usage-data/skillsbar}"
APP_BUNDLE="$BUILD_ROOT/SkillsBar.app"
LAUNCH_RECEIPT="$BUILD_ROOT/SkillsBar.launch-receipt.json"

stop_existing() {
  pkill -x "$APP_NAME" >/dev/null 2>&1 || true
  pkill -f "$APP_NAME.app/Contents/MacOS/$APP_NAME" >/dev/null 2>&1 || true
}

launch_app() {
  "$ROOT_DIR/Launch.command"
}

case "$MODE" in
  run)
    launch_app
    ;;
  --debug|debug)
    (cd "$ROOT_DIR" && NO_OPEN=1 ./Launch.command)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    launch_app || true
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    launch_app || true
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    stop_existing
    SKILLSBAR_REQUIRE_LAUNCHSERVICES=1 launch_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    [[ -f "$LAUNCH_RECEIPT" ]]
    [[ "$(/usr/bin/plutil -extract launch_method raw "$LAUNCH_RECEIPT")" == "launchservices_open" ]]
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
