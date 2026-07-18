---
schema_version: pr-green-sweep/v1
artifact_id: skillsbar-pr-2-green-sweep-2026-07-18
repo: jscraik/skillsbar
pr_url: https://github.com/jscraik/skillsbar/pull/2
head_before: 587cad7640c1be48ee6d2b7c86fde1cf67b66a4b
---

# SkillsBar PR green sweep

## URL-first action queue

- https://github.com/jscraik/skillsbar/pull/2 — feat: add nine-gate Skills SDK evidence view
  - Head before repair: codex/review-popover-delivery @ 587cad7640c1be48ee6d2b7c86fde1cf67b66a4b
  - State before repair: mergeable but blocked; eight current unresolved CodeRabbit threads; Analyze (swift) failed.
  - Queue: auto_fixable_now; source and proof edits were made in an isolated checkout at /private/tmp/skillsbar-pr2.
  - Next hosted gate: push the validated repair, wait for fresh checks/review, then re-read mergeability and thread state.

## Review and CI accounting

- Fixed the CodeQL compiler blocker at PipelineEvidenceLoader.swift:503 by comparing Set<String> with Set([digest]).
- Hardened .github/workflows/codeql.yml with immutable action SHAs, persist-credentials: false, least-privilege documentation, and concurrency cancellation.
- Made the animation audit threshold explicitly exclude modal, drawer, and marketing exceptions.
- Made animation plan-directory resolution deterministic through the .workflow-owner marker and aligned PLAN-TEMPLATE.md with the resolved directory and recon-verified token path.
- Added contract assertions covering the marker, fallback, template, numbering, plan, and README reuse.
- Reconciled the nine-gate validation receipt to the current 65-test focused lane and 67-test full suite.
- Pointed the superseded Worker handoff at #review-follow-up-repair-closeout.
- Changed visible and accessibility copy from stages evidenced to gates evidenced.
- Restricted selected-skill evidence enumeration to the resolved Skills/ subtree after symlink and traversal resolution.
- Added the explicit test-class deinitializer required by the review lint signal.

## Recurring-finding ledger

| Theme | Evidence | Durable response |
| --- | --- | --- |
| Stale or contradictory validation claims | Review threads 3606263740, 3606263748, 3606263755 | Current receipt count, exact commands, and supersession anchor are recorded in governed .harness artifacts and the PR body. |
| Mutable CI action and workflow safety | Review threads 3606263732, 3606263737; CodeQL job failure 87996551765 | Immutable SHAs, checkout credential isolation, permission rationale, and concurrency are now explicit. |
| Ambiguous animation plan ownership | Review threads 3606263725, 3606263727 and outside-diff template finding | .workflow-owner marker, deterministic fallback, recon-verified token placeholder, and a contract test prevent drift. |
| Candidate-path containment | Latest CodeRabbit duplicate finding for DashboardLoader.swift | Resolved Skills/ subtree checks now run before metadata, fingerprint, or command collection. |

## Validation evidence

Command: HOME=/private/tmp/skillsbar-pr2-build-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-build-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-build-clang DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer timeout 300 swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-build -> pass (Swift build completed; the previous CodeQL compiler error no longer reproduces)

Command: HOME=/private/tmp/skillsbar-pr2-focused-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-focused-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-focused-clang DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer timeout 600 swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-focused --filter 'ReviewPopoverTests|PipelineEvidenceLoaderTests' -> pass (65 tests, 1 opt-in integration test skipped, 0 failures)

Command: HOME=/private/tmp/skillsbar-pr2-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-test-clang DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer timeout 600 swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-test -> pass (67 tests, 1 opt-in integration test skipped, 0 failures)

Command: HOME=/private/tmp/skillsbar-pr2-package-home XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-package-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-package-clang SKILLSBAR_BUILD_ROOT=/private/tmp/skillsbar-pr2-package-build bash script/package_app.sh debug -> pass (debug app bundle produced; post-build bundle checks pass)

Command: /usr/libexec/PlistBuddy -c 'Print :CFBundleIconFile' /private/tmp/skillsbar-pr2-package-build/SkillsBar.app/Contents/Info.plist -> pass (SkillsSDKIcon.icns)

Command: file /private/tmp/skillsbar-pr2-package-build/SkillsBar.app/Contents/Resources/SkillsSDKIcon.icns -> pass (Mac OS X icon)

Command: codesign --verify --deep --strict --verbose=2 /private/tmp/skillsbar-pr2-package-build/SkillsBar.app -> pass (valid on disk and satisfies its designated requirement)

Command: bash -n script/package_app.sh -> pass

Command: git diff --check -> pass

Command: hidden-character scan over .codex/skills/improve-animations -> pass (HIDDEN_CHARACTER_SCAN_OK)

Command: markdownlint-cli2 .codex/skills/improve-animations/AUDIT.md .codex/skills/improve-animations/PLAN-TEMPLATE.md .codex/skills/improve-animations/SKILL.md -> fail (73 inherited MD013 line-length findings remain; no MD031 fence error was introduced)

Command: swiftlint lint --strict -> blocked (SwiftLint is not installed in the isolated validation environment)

## CodeRabbit CLI review

Command: `timeout 600 op run --env-file=/Users/jamiecraik/.codex/.env -- coderabbit review --agent --type committed --base main` -> fail/blocked (the CLI authenticated and analyzed the committed diff, emitted review findings, then exceeded the 600-second bounded timeout without a terminal summary; no stored finding set was available afterward)

The bounded CLI run was used as an independent review signal, not as an approval. Valid findings were applied in `fc21cdc` for Reduce Motion, Tessl registry wording and comparison gating, active-receipt action copy, CodeQL job permissions, animation units and plan ownership, superseded evidence labels, and live CLI observation semantics. Historical-handoff and prior-PR-description findings were retained as provenance and not reopened. The CLI did not produce current-head approval evidence.

## Explicit CodeRabbit waiver

The operator confirmed that the `Prepaid credits exhausted — enable usage-based reviews` status is a false-positive merge blocker because CodeRabbit had already reviewed PR #2. The waiver is recorded in `.harness/steering-feedback/2026-07-18-coderabbit-reviewed-waiver.json` and applies only to the later provider-credit status. It does not waive the separate GitHub Analyze (swift) check, branch mergeability, or any non-CodeRabbit review policy.

## Follow-up compiler repair

GitHub Analyze (swift) on `9e3059e` failed because a local `scenarioIDs` array shadowed the `scenarioIDs(in:)` helper. The implementation now uses `receiptScenarioIDs`, leaving the helper unambiguous for the hosted Swift toolchain.

Command: XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-shadow-focused-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-shadow-focused-clang DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer timeout 600 swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-shadow-focused --filter PipelineEvidenceLoaderTests -> pass (12 tests, 1 opt-in integration test skipped, 0 failures)

Command: XDG_CACHE_HOME=/private/tmp/skillsbar-pr2-shadow-full-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-pr2-shadow-full-clang DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer timeout 600 swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-pr2-shadow-full -> pass (67 tests, 1 opt-in integration test skipped, 0 failures)

## Dirty ownership and cleanup

- The canonical /Users/jamiecraik/dev/skillsbar checkout remains on dirty main and was not switched, staged, reset, cleaned, or merged.
- Only the isolated PR checkout owns the repair diff. No branch or worktree cleanup is eligible until hosted head, checks, reviews, and merge state are refreshed.

## Claims boundary and stop rule

This receipt proves local source/build/test/package checks for the isolated repair. It does not yet prove the repair is pushed, hosted checks are green, CodeRabbit has re-reviewed the new head, review threads are resolved, the PR is approved, or the PR is merged. Stop before merge if any current-head check, review, or required readiness receipt is missing; do not claim hosted readiness from local proof alone.
