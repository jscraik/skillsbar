#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_ROOT="${SKILLSBAR_BUILD_ROOT:-$HOME/.codex/usage-data/skillsbar}"
APP_DIR="$BUILD_ROOT/SkillsBar.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/SkillsBar"
LAUNCH_RECEIPT="$BUILD_ROOT/SkillsBar.launch-receipt.json"
LOCK_DIR="$BUILD_ROOT/launch.lock"
LOCK_PID_FILE="$LOCK_DIR/pid"
LOCK_OWNED=0
EVIDENCE_MODE="live_local_evidence"
case "${SKILLSBAR_DEMO_MODE:-}" in
  1|true|TRUE|yes|YES|on|ON)
    EVIDENCE_MODE="deterministic_demo_fixture"
    ;;
esac

mkdir -p "$BUILD_ROOT"
# shellcheck disable=SC2329 # Invoked by the trap below.
cleanup() {
  if [[ "$LOCK_OWNED" == "1" ]]; then
    lock_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"
    if [[ -z "$lock_pid" || "$lock_pid" == "$$" ]]; then
      rm -rf "$LOCK_DIR"
    fi
  fi
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

while ! mkdir "$LOCK_DIR" 2>/dev/null; do
  existing_pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || true)"
  if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
    echo "Another SkillsBar build is running (pid $existing_pid); waiting..."
    sleep 1
  else
    rm -rf "$LOCK_DIR"
  fi
done
LOCK_OWNED=1
printf '%s\n' "$$" > "$LOCK_PID_FILE"
rm -f "$LAUNCH_RECEIPT"

stop_existing() {
  if command -v pkill >/dev/null 2>&1; then
    pkill -x SkillsBar >/dev/null 2>&1 || true
    pkill -f "SkillsBar.app/Contents/MacOS/SkillsBar" >/dev/null 2>&1 || true
    sleep 0.4
  fi
}

stop_existing

"$SCRIPT_DIR/script/package_app.sh" debug

if [[ "${NO_OPEN:-0}" == "1" ]]; then
  cat > "$LAUNCH_RECEIPT" <<JSON
{
  "schema_version": "skillsbar-launch/v1",
  "status": "built_not_launched",
  "launch_method": "none",
  "evidence_mode": "$EVIDENCE_MODE",
  "app_path": "$APP_DIR",
  "executable_path": "$EXECUTABLE"
}
JSON
  exit 0
fi

echo "Opening menu-bar prototype..."
OPEN_OUTPUT="$BUILD_ROOT/SkillsBar.open.log"
if /usr/bin/open -n "$APP_DIR" >"$OPEN_OUTPUT" 2>&1; then
  cat > "$LAUNCH_RECEIPT" <<JSON
{
  "schema_version": "skillsbar-launch/v1",
  "status": "launched",
  "launch_method": "launchservices_open",
  "evidence_mode": "$EVIDENCE_MODE",
  "app_path": "$APP_DIR",
  "executable_path": "$EXECUTABLE"
}
JSON
  for _ in {1..10}; do
    if pgrep -x SkillsBar >/dev/null 2>&1; then
      exit 0
    fi
    sleep 0.4
  done
fi

OPEN_ERROR="$(tr '\n' ' ' < "$OPEN_OUTPUT" | sed 's/"/\\"/g')"
DIRECT_FALLBACK_STATUS="disabled"
if [[ "${SKILLSBAR_DIRECT_LAUNCH_FALLBACK:-1}" == "1" && "${SKILLSBAR_REQUIRE_LAUNCHSERVICES:-0}" != "1" ]]; then
  DIRECT_FALLBACK_STATUS="attempted"
  "$EXECUTABLE" >"$BUILD_ROOT/SkillsBar.direct-launch.log" 2>&1 &
  direct_pid=$!
  sleep 0.4
  direct_alive=1
  for _ in {1..10}; do
    if ! kill -0 "$direct_pid" 2>/dev/null; then
      direct_alive=0
      break
    fi
    sleep 0.4
  done
  if [[ "$direct_alive" == "1" ]]; then
    cat > "$LAUNCH_RECEIPT" <<JSON
{
  "schema_version": "skillsbar-launch/v1",
  "status": "launched",
  "launch_method": "direct_executable_fallback",
  "evidence_mode": "$EVIDENCE_MODE",
  "app_path": "$APP_DIR",
  "executable_path": "$EXECUTABLE",
  "launchservices_error": "$OPEN_ERROR"
}
JSON
    exit 0
  fi
  DIRECT_FALLBACK_STATUS="exited"
elif [[ "${SKILLSBAR_REQUIRE_LAUNCHSERVICES:-0}" == "1" ]]; then
  DIRECT_FALLBACK_STATUS="disabled_for_live_verify"
fi

cat > "$LAUNCH_RECEIPT" <<JSON
{
  "schema_version": "skillsbar-launch/v1",
  "status": "blocked_launchservices",
  "launch_method": "launchservices_open",
  "evidence_mode": "$EVIDENCE_MODE",
  "app_path": "$APP_DIR",
  "executable_path": "$EXECUTABLE",
  "open_error": "$OPEN_ERROR",
  "direct_launch_fallback": "$DIRECT_FALLBACK_STATUS",
  "direct_launch_log": "$BUILD_ROOT/SkillsBar.direct-launch.log",
  "manual_open_command": "open -n '$APP_DIR'"
}
JSON

echo "LaunchServices open failed; app bundle was built but not launched." >&2
cat "$OPEN_OUTPUT" >&2
echo "" >&2
echo "Try from a normal macOS Terminal or Finder session:" >&2
echo "  open -n '$APP_DIR'" >&2
echo "Launch receipt: $LAUNCH_RECEIPT" >&2
exit 1
