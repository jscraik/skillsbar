---
schema_version: 1
artifact_id: skillsbar-nine-gate-ui-validation-2026-07-14
artifact_type: local-validation-receipt
date: 2026-07-14
status: local_validation_pass_live_ui_blocked
---

# SkillsBar nine-gate UI validation

## Implemented boundary

- Replaced the visible six-stage weighted posture with the nine ordered release
  gates from Candidate identity through Runtime truth.
- Preserved early package, risk, and scenario observations as `held`; they do
  not promote a downstream gate.
- Added a live Tessl registry treatment with explicit version-only comparison.
- Added a sanitized last-known registry cache. When the Tessl CLI is missing,
  cached metrics are muted and labelled as historical, not candidate proof.
- Restored the spec-backed `404 x 720` laptop canvas with internal vertical
  scrolling, compact structural spacing, safe top and bottom insets, and a
  fixed close control with Escape and accessibility support.
- Added deterministic `live` and `no-cli` UI fixtures at `404 x 720`.
- Headless snapshots use the app's opaque graphite fallback because AppKit blur
  composition is not a reliable off-screen proof surface. The normal live app
  retains its translucent material treatment.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build --filter ReviewPopoverTests` -> pass (47 focused tests; includes 1,000 nine-gate ordering iterations, complete-content overflow proof, cache round-trip, live/no-CLI semantic checks, and both snapshot renders)

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build` -> pass (48 tests, 0 failures)

Command: `HOME=/private/tmp/skillsbar-parallel-home XDG_CACHE_HOME=/private/tmp/skillsbar-parallel-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-parallel-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --parallel --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-parallel-build` -> pass (48 tests completed under parallel scheduling)

Command: `HOME=/private/tmp/skillsbar-home XDG_CACHE_HOME=/private/tmp/skillsbar-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build` -> pass (debug executable built from an isolated build root)

Command: `NO_OPEN=1 ./Launch.command` -> pass (debug arm64 app bundle created and ad-hoc signature replaced successfully)

Command: `codesign --verify --deep --strict --verbose=2 /Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.app` -> pass (bundle is valid on disk and satisfies its designated requirement)

Command: `git diff --check` -> pass (no whitespace errors in the unstaged implementation diff)

Command: `SKILLSBAR_REVIEW_FIXTURE=live /private/tmp/skillsbar-test-build/debug/SkillsBar --snapshot /private/tmp/skillsbar-compact-live.png` -> pass (deterministic live-registry state rendered at `404 x 720` with the fixed close control visible)

Command: `SKILLSBAR_REVIEW_FIXTURE=no-cli /private/tmp/skillsbar-test-build/debug/SkillsBar --snapshot /private/tmp/skillsbar-compact-no-cli.png` -> pass (deterministic CLI-unavailable historical state rendered at `404 x 720`)

Command: `script/build_and_run.sh --verify` -> blocked (LaunchServices in the current Codex desktop coalition returned `NSOSStatusErrorDomain Code=-10827 kLSNoExecutableErr`; the generated executable exists, is arm64, and `codesign --verify --deep --strict` passes)

Command: `/Users/jamiecraik/.codex/usage-data/skillsbar/SkillsBar.app/Contents/MacOS/SkillsBar` -> blocked (direct AppKit launch aborted in `_RegisterApplication` under parent coalition `com.openai.codex`; crash evidence: `/Users/jamiecraik/Library/Logs/DiagnosticReports/SkillsBar-2026-07-14-210528.ips`)

## Claims boundary

The evidence proves local compilation, deterministic rendering of both requested
provenance states, model/cache behavior, clipboard regression coverage, stress
coverage, and creation of a signed local debug bundle. It does not prove a live
menu-bar interaction or close-button click in this session, a current authenticated Tessl response,
canonical package-digest equality, installed-runtime behavior, packaging for
distribution, notarization, publication, or release readiness.

## PR #2 follow-up validation

The historical 48-test counts above are superseded for the current candidate by
the focused follow-up below. The follow-up includes the async data-source,
candidate-bound Tessl registry, dynamic stage-count, and decoded-pixel
regressions added during PR triage.

Command: `HOME=/private/tmp/skillsbar-pr2-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-test-build -Xswiftc -gnone --filter "ReviewPopoverTests|PipelineEvidenceLoaderTests"` -> pass (61 tests executed, 1 integration test skipped, 0 failures)

Command: `HOME=/private/tmp/skillsbar-pr2-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-full-build -Xswiftc -gnone` -> pass (60 tests executed, 1 integration test skipped, 0 failures)

Command: `NO_OPEN=1 SKILLSBAR_BUILD_ROOT=/private/tmp/skillsbar-pr2-package ./Launch.command` -> pass (debug arm64 app bundle built and ad-hoc signed)

Command: `/usr/bin/plutil -p /private/tmp/skillsbar-pr2-package/SkillsBar.app/Contents/Info.plist | rg "CFBundleIconFile|CFBundleIdentifier"` -> pass (bundle metadata points to the packaged SkillsSDKIcon.png resource)

Command: `codesign --verify --deep --strict --verbose=2 /private/tmp/skillsbar-pr2-package/SkillsBar.app` -> pass (bundle is valid on disk and satisfies its designated requirement)

Command: `git diff --check` -> pass (no whitespace diagnostics)

This follow-up proves the current source and focused regressions only; it does
not prove hosted review approval, remote merge, installed-app runtime, or Tessl
publication.
