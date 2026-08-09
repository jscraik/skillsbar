# SkillsBar ReviewPresentation cleanup — Worker handoff

```yaml
schema: bounded-child-lane/v1
artifact_id: worker-2026-07-19-review-presentation-model-cleanup
task_id: skillsbar-review-presentation-model-cleanup-2026-07-19
role: Worker
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface did not expose an observed child runtime attestation
base_head: eb5bd31
status: focused_local_validation_pass
```

## Scope and preservation boundary

Changed only the packet-authorized cleanup slice:

- `Sources/SkillsBar/Models/DashboardModels.swift`
- `Tests/SkillsBarTests/ReviewPopoverTests.swift`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `.harness/steering-feedback/2026-07-19-legacy-review-presentation-cleanup.json`
- this Worker handoff artifact

Preserved without modification:

- staged `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- staged `Sources/SkillsBar/Views/ReleaseEvidenceView.swift`
- staged `Sources/SkillsBarCore/Shell.swift`
- staged `Tests/SkillsBarCoreTests/ShellTests.swift`
- existing unstaged UI-route/legacy-view cleanup in `AGENTS.md`, `README.md`, and `DashboardView.swift`
- untracked `.codex/skills/find-animation-opportunities/`
- package, launch, app-install, registry, hosted, signing, and release state

## Caller map and deletion decision

Pre-edit bounded source inspection found one declaration and no production
consumer:

- `Sources/SkillsBar/Models/DashboardModels.swift:830` declared `ReviewPresentation`.
- No source under `Sources/SkillsBar` constructed or consumed it.
- `Tests/SkillsBarTests/ReviewPopoverTests.swift` contained nine constructions,
  in these retired-model tests:
  - `testReviewPresentationExplainsLocalAndRegistryTruth`
  - `testPendingPresentationDoesNotClaimReviewOrSuccess`
  - `testHealthyPresentationUsesPositiveSemantics`
  - `testUnavailableRegistryDoesNotRenderSuccessBridge`
  - `testLocalAdvisoryPresentationIsBlueAndNotHealthy`
  - `testSecurityFindingOutranksMissingQualityAndImpactScores`
  - `testFailedSecurityUsesDangerTone`
  - `testLowLocalScoreIsNotPresentedAsHealthy`
  - `testRegistryFindingIsNotDescribedAsClean`

Three retired-model tests also asserted active model behaviour. Those assertions
were retained, rather than discarded:

- missing quality/impact scores still yield `dashboard.score == nil` in
  `testReviewFixtureMatchesImplementationHandoffContract`;
- advisory security retains its disposition and tone checks in
  `testSecurityDispositionUsesSeverityFirstPrecedence`;
- flagged registry evidence retains its review-required check in
  `testRegistryMetricTonesFollowActualValues`.

The active root remains `DashboardView` -> `ReleaseEvidenceView`; no current
view, snapshot, or registry test was removed.

## TDD evidence

Added `testRetiredReviewPresentationIsAbsentFromModelAndLegacyTests` to
`SkillContractTests`. It reads the two canonical files and requires neither to
contain `ReviewPresentation`.

The first focused execution was red: both absence assertions failed while the
model declaration and legacy test constructions existed. The cleanup then
removed the unreferenced model and only the nine retired-model test functions.
The focused target compiled `DashboardModels.swift`, the retained
`ReviewPopoverTests.swift` target, `ReleaseEvidenceView.swift`, and the test
bundle before executing green.

The steering-feedback record is now `implemented` and records both the expected
red result and the green proof. It was schema-validated after the update.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> fail (expected red: `testRetiredReviewPresentationIsAbsentFromModelAndLegacyTests` failed two absence assertions before cleanup.)

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (green: 4 tests, 0 failures; the full app and retained test target compiled.)

Command: `python3 /Users/jamiecraik/.codex/scripts/validate-steering-feedback.py --input .harness/steering-feedback/2026-07-19-legacy-review-presentation-cleanup.json --json` -> pass (validator returned `status: pass` with no errors.)

Command: `zsh -lc 'if rg -n "\\bReviewPresentation\\b" Sources/SkillsBar/Models/DashboardModels.swift Tests/SkillsBarTests/ReviewPopoverTests.swift; then exit 11; else print "No ReviewPresentation production-model or legacy-test references remain."; fi'` -> pass (zero references in the retired production-model and legacy-test surfaces.)

Command: `rg -n "ReleaseEvidenceView\\(" Sources/SkillsBar/Views/DashboardView.swift` -> pass (active root remains at `DashboardView.swift:20`.)

Command: `git diff --check` -> pass (no whitespace diagnostics.)

`ReviewPopoverTests` was not rerun. The packet forbids rerunning its separate
snapshot lane because its mismatch is bound to the staged visual baseline and
staged `ReleaseEvidenceView.swift`, both outside this cleanup scope.

## Residual risk and claims boundary

This Worker lane proves the retired source/test cleanup, retained active-model
assertions, the focused source-contract test, and a local compile of the full
test target. It does not prove visual snapshot equivalence, the full suite,
live MenuBarExtra behaviour, installed-bundle state, Tessl/registry truth,
hosted checks/review, signing, notarization, publication, or release readiness.

Fresh independent QA disproof and adversarial review are still required.

WROTE: .harness/reports/worker-handoffs/2026-07-19-review-presentation-model-cleanup-worker.md
