# SkillsBar current UI contract routing and legacy view cleanup — Worker handoff

```yaml
schema: bounded-child-lane/v1
artifact_id: worker-2026-07-19-ui-contract-routing-and-legacy-view-cleanup
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: Worker
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface did not expose an observed child runtime
base_head: eb5bd31
status: partial_local_validation_preexisting_snapshot_blocker
```

## Scope and preservation boundary

Changed only the packet-authorized canonical files:

- `AGENTS.md`
- `README.md`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `.harness/steering-feedback/2026-07-19-current-ui-contract-routing.json`
- this handoff artifact

Preserved without modification:

- staged `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- staged `Sources/SkillsBar/Views/ReleaseEvidenceView.swift`
- staged `Sources/SkillsBarCore/Shell.swift`
- staged `Tests/SkillsBarCoreTests/ShellTests.swift`
- untracked `.codex/skills/find-animation-opportunities/`
- package, launch, app-install, registry, hosted, signing, and release state.

## TDD evidence

The new `testDefaultUIWorkRoutesToApprovedPipelinePostureContract` asserts both
metadata sides of the route: the 2026-07-10 pipeline-posture specification is
the approved current contract and its mockup is named by the route; the
2026-07-09 review-popover specification is explicitly superseded and names its
successor.

The test also requires `AGENTS.md` and `README.md` to point at the current
pipeline-posture route. The initial red execution failed on those four route
assertions before the docs changed. The green execution passed after the docs
were corrected.

`AGENTS.md` and `README.md` now route current UI work through the approved
pipeline-posture spec and mockup, active `ReleaseEvidenceView`, and focused
`ReviewPopoverTests`. They retain the review-popover specification, mockups,
and syntheses as historical/reference-only material.

## Caller and deletion evidence

Before deletion, `DashboardView` had a single active content root:
`ReleaseEvidenceView(dashboard:isRefreshing:)`. App and snapshot callers both
instantiate `DashboardView`; no caller instantiated the private historical
pipeline/review roots.

Removed the unreferenced private legacy graph, including the old posture
header, readiness/card/row components, old Tessl card/action components,
review-popover component graph, their font/copy-motion helpers, logo views,
dividers, and hex shape. Retained the active backdrop, close control and its
button style, image loaders/resource loader, and shared colour helpers.

Post-change source inspection confirms `DashboardView` still renders
`ReleaseEvidenceView`, the active release view and menu-bar icon still use the
retained loaders, and no private legacy view declarations remain.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> fail (expected red phase: the new current-route test failed four AGENTS/README assertions because the pre-change documentation did not name the approved 2026-07-10 route.)

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (green phase: 2 `SkillContractTests` executed with zero failures; Swift rebuilt `DashboardView.swift` and linked the test bundle.)

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter ReviewPopoverTests` -> fail (53 tests executed; 52 passed. `testReviewFixtureRenderMatchesRetainedBaseline` observed pixel difference `0.02619804474319981`, above `0.0005`. The test renders the active release evidence path and the staged pre-existing `ReleaseEvidenceView.swift` adds motion/visual rendering changes. This Worker did not modify that file or the retained baseline evidence.)

Command: `zsh -lc 'if rg -n "PipelinePostureHeader|PipelineStageCard|PipelineStageRow|TesslRegistryCard|PipelineAction|ReviewHeader|ReviewTriggerCard|ReviewAction|PackageIdentity" Sources Tests; then exit 1; else print "No removed legacy roots remain in Sources or Tests."; fi'` -> fail (unsupported broad source-text shape: `PackageIdentity` is intentionally present in an unrelated test method name, so this did not establish a remaining private declaration.)

Command: `zsh -lc 'if rg -n "^private struct (PipelinePostureHeader|PipelineReadinessSummary|WeightedReadinessBar|PipelineStageCard|PipelineConnector|PipelineStageRow|TesslRegistryCard|HistoricalMetricColumn|PipelineAction|ReviewHeader|ScoreHex|PackageIdentity|RefreshStatus|ReviewTriggerCard|MetricColumn|RegistryEvidenceRow|RegistryVisibilityBadge|RegistryMetric|EvidenceBridge|ReviewAction|ScaledSystemFontModifier|CopyConfirmationMotion|SkillsSDKLogoView|TesslLogoView|QuietDivider|VerticalDivider|RoundedHexagon)" Sources/SkillsBar/Views/DashboardView.swift; then exit 1; else print "No private legacy view roots remain in DashboardView.swift."; fi'` -> pass (corrected declaration-only probe found no removed private legacy roots.)

Command: `git diff --check` -> pass (no whitespace diagnostics.)

Command: `python3 /Users/jamiecraik/dev/configs/codex/scripts/validate-steering-feedback.py --input .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json --json` -> pass (the record has no errors and the validator reports `status: pass`.)

The full canonical suite was **not run**. The packet makes a validation failure
caused by pre-existing staged state a stop condition, and the affected
`ReviewPopoverTests` lane reached that condition.

## QA-disproof recovery

Fresh independent QA accepted the active source/deletion and current routing
claims but rejected the first contract test as incomplete: it asserted that the
2026-07-10 route existed without asserting that both maintained documents kept
the 2026-07-09 material historical/reference-only and non-default.

This bounded recovery changed only `SkillContractTests.swift`, the steering
record, and this handoff. The strengthened test now requires both documents to
state the current 2026-07-10 route, requires AGENTS to call the 2026-07-09
material historical and non-default, requires README to call it
historical/reference-only and non-governing, and rejects the earlier stale
default-route sentences.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (QA-recovery run: 2 tests executed with zero failures.)

`ReviewPopoverTests` was not retried, per the QA instruction and the existing
pre-existing staged snapshot blocker.

## Adversarial-review recovery

Fresh adversarial review accepted the route guard and active dependency
preservation, then found one remaining dead helper: `Color.focusAccent` in
`DashboardView.swift`. The private legacy review-action graph had been its last
consumer, so its declaration no longer had a production caller.

This bounded recovery changed only `DashboardView.swift`,
`SkillContractTests.swift`, and this handoff. It first added
`testDashboardViewDoesNotRetainDeletedFocusAccent`, which scans the maintained
source file and rejects any retained `focusAccent` dependency. That test failed
in the required red phase. The implementation change removed only the dead
`Color.focusAccent` declaration.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> fail (expected red phase: `testDashboardViewDoesNotRetainDeletedFocusAccent` found the retained declaration.)

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (green phase: 3 tests executed with zero failures.)

Command: `zsh -lc 'set -o pipefail; matches=$(rg -n "\bfocusAccent\b" Sources Tests); printf "%s\n" "$matches"; test "$(printf "%s\n" "$matches" | wc -l | tr -d " ")" -ge 2'` -> fail (the adversarial probe's original `>= 2` predicate now sees only the new test assertion, not a production declaration plus consumer. This is the expected post-removal shape, not a remaining source dependency.)

Command: `zsh -lc 'if rg -n "\bfocusAccent\b" Sources; then exit 1; else print "No production focusAccent dependency remains."; fi'` -> pass (no production source reference remains.)

No documentation, steering record, staged user path, app/runtime, package, or
visual-snapshot lane changed or reran during this recovery. Fresh QA and fresh
adversarial review are required for the amended candidate.

## Residual risk and next bounded action

The current full visual snapshot baseline is not reconciled with the
pre-existing staged `ReleaseEvidenceView.swift` animation changes. Its owner
must decide whether to restore expected visual equivalence, update the retained
baseline under the appropriate evidence authority, or adjust the snapshot
contract. After that decision, rerun `ReviewPopoverTests` and only then the
full canonical suite.

## Claims boundary

This handoff establishes source/document routing, source deletion, a focused
contract-test red/green sequence, and `git diff --check`. It does not establish
the full visual snapshot lane, full-suite status, live MenuBarExtra behavior,
installed-bundle state, Tessl or registry authority, hosted checks/reviews,
signing, notarization, publication, or release readiness.

WROTE: .harness/reports/worker-handoffs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-worker.md
