# Skills SDK Review Popover Implementation Snapshot

schema_version: 1

This artifact records the deterministic app-rendered review-popover snapshot. It proves that the SwiftUI implementation can render the fixture state at `404 x 720` pixels through the product's snapshot entrypoint. It does not prove that LaunchServices opened the live MenuBarExtra, that keyboard focus traversed the system popover, or that a click wrote to the live system clipboard.

## Artifact

- Snapshot: `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- Fixture: `SKILLSBAR_REVIEW_FIXTURE=1`
- Visual target: `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-implementation-handoff.png`
- Rendered size: `404 x 720`

## Evidence

Command: `HOME=/private/tmp/skillsbar-tdd-final-snapshot-home XDG_CACHE_HOME=/private/tmp/skillsbar-tdd-final-snapshot-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-tdd-final-snapshot-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer SKILLSBAR_REVIEW_FIXTURE=1 swift run --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-tdd-final-snapshot-build -Xswiftc -gnone SkillsBar --snapshot .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png` -> pass (app wrote the final deterministic snapshot from the canonical review fixture)

Command: `HOME=/private/tmp/skillsbar-recommendations-final-home XDG_CACHE_HOME=/private/tmp/skillsbar-recommendations-final-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-recommendations-final-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-recommendations-final-build -Xswiftc -gnone --filter ReviewPopoverTests` -> pass (15 review-popover tests, 0 failures)

Command: `HOME=/private/tmp/skillsbar-recommendations-full-home XDG_CACHE_HOME=/private/tmp/skillsbar-recommendations-full-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-recommendations-full-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-recommendations-full-build -Xswiftc -gnone` -> pass (16 tests, 0 failures)

Command: `HOME=/private/tmp/skillsbar-tdd-security-final-home XDG_CACHE_HOME=/private/tmp/skillsbar-tdd-security-final-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-tdd-security-final-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-tdd-security-final-build -Xswiftc -gnone --filter ReviewPopoverTests` -> pass (19 focused tests, 0 failures)

Command: `HOME=/private/tmp/skillsbar-tdd-security-all-home XDG_CACHE_HOME=/private/tmp/skillsbar-tdd-security-all-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-tdd-security-all-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-tdd-security-all-build -Xswiftc -gnone` -> pass (20 tests, 0 failures)

Command: `sips -g pixelWidth -g pixelHeight .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png` -> pass (`pixelWidth: 404`, `pixelHeight: 720`)

Command: `NO_OPEN=1 ./Launch.command` -> pass (the launcher built, signed, and replaced the local app bundle with debug-symbol generation disabled for this prototype path)

Command: `SKILLSBAR_REVIEW_FIXTURE=1 script/build_and_run.sh --verify` -> blocked (the refreshed bundle built and signed successfully, but the Codex-session LaunchServices call still returned `kLSNoExecutableErr`; receipt: `/Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.launch-receipt.json`)

Command: `codesign --verify --deep --strict /Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.app` -> pass (installed app signature verified; executable is an arm64 Mach-O at the declared bundle path)

Command: `SKILLSBAR_REVIEW_FIXTURE=1 /Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.app/Contents/MacOS/SkillsBar` -> blocked (the GUI executable exited with status 1 and no diagnostic when started directly from the headless Codex process; this does not prove the MenuBarExtra runtime path)

Command: `find /Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.app -maxdepth 3 -type f -print` plus `file` and `codesign -dv --verbose=2` inspection -> pass (the declared arm64 executable exists, is executable, and the bundle has a valid ad-hoc signature; the remaining failure is the Codex-session LaunchServices lane rather than a missing bundle executable)

## Visual Inspection

- The full action panel is visible inside the rendered height.
- The top-right details control is absent.
- The local review trigger is expanded without a chevron.
- Tessl Registry is visually secondary to local evidence.
- The mixed bridge combines a success check with an amber finding marker.
- The canonical command is displayed in a stable three-line monospace field.
- Pending, healthy, and registry-unavailable semantics are covered by presentation tests and no longer inherit review-state success or warning claims.
- The status-item asset is an `18 x 18 pt` template image, and copy failures do not report success.
- The review score uses a regular rounded hexagon, and visibility appears only as Tessl Registry metadata.
- Registry metric tones derive from their actual values; the fixture's `63%` impact is warning-colored.
- Sanitized Private, Public, and missing-visibility Tessl payloads protect the live metadata mapping.
- A rendered-pixel regression test compares the production `DashboardView` fixture against this retained baseline.
- Local and registry security presentation share one severity-first disposition, including cyan Advisory without a false healthy state.
- Canonical-path registry parsing rejects unrelated nested access/count/security/version fields.
- Adaptive rendering covers semantic variants plus accessibility-sized text, Reduce Transparency, and Increased Contrast.
- Shell execution disables zsh startup files so command evidence is not contaminated by workstation profile output.

## Remaining Live Proof

- Open the MenuBarExtra from a normal user session and capture the anchored popover.
- Activate Copy inspect command and compare `NSPasteboard.general` with `reviewInspectCommand`.
- Traverse the copy control with keyboard focus and verify its focus ring.
- Confirm the native-only motion classification with Reduce Motion enabled.
