#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=version.env
source "$ROOT_DIR/version.env"

APP_NAME="SkillsBar"
BUILD_ROOT="${SKILLSBAR_BUILD_ROOT:-$ROOT_DIR/dist}"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
ARCHES_VALUE="${ARCHES:-arm64 x86_64}"
BUNDLE_ID="${SKILLSBAR_BUNDLE_ID:-}"
ZIP_PATH="$BUILD_ROOT/${APP_NAME}-macos-universal-${MARKETING_VERSION}.zip"
NOTARY_ZIP="$BUILD_ROOT/${APP_NAME}-notarization.zip"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -n "${APP_IDENTITY:-}" ]] || fail "APP_IDENTITY must name an installed Developer ID Application certificate"
[[ -n "$BUNDLE_ID" ]] || fail "SKILLSBAR_BUNDLE_ID must be set for a public release"
[[ "$BUNDLE_ID" != local.* ]] || fail "SKILLSBAR_BUNDLE_ID must not use the development-only local.* namespace"
security find-identity -p codesigning -v | grep -F "$APP_IDENTITY" >/dev/null \
  || fail "APP_IDENTITY was not found in the login keychain"

if [[ -z "${NOTARY_PROFILE:-}" ]]; then
  fail "NOTARY_PROFILE must name an xcrun notarytool keychain profile"
fi

mkdir -p "$BUILD_ROOT"
ARCHES="$ARCHES_VALUE" SKILLSBAR_BUILD_ROOT="$BUILD_ROOT" \
  SKILLSBAR_SIGNING=identity APP_IDENTITY="$APP_IDENTITY" \
  "$ROOT_DIR/script/package_app.sh" release

rm -f "$NOTARY_ZIP" "$ZIP_PATH"
/usr/bin/ditto --norsrc -c -k --keepParent "$APP_BUNDLE" "$NOTARY_ZIP"
xcrun notarytool submit "$NOTARY_ZIP" --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP_BUNDLE"
/usr/bin/xattr -cr "$APP_BUNDLE"
find "$APP_BUNDLE" -name '._*' -delete
xcrun stapler validate "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

if command -v syspolicy_check >/dev/null 2>&1; then
  syspolicy_check distribution "$APP_BUNDLE"
else
  /usr/sbin/spctl --assess --type execute --verbose=2 "$APP_BUNDLE"
fi

/usr/bin/ditto --norsrc -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
rm -f "$NOTARY_ZIP"
printf 'Created notarized release: %s\n' "$ZIP_PATH"
