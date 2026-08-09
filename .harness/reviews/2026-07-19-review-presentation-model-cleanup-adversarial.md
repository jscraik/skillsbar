# SkillsBar ReviewPresentation cleanup — adversarial review

```yaml
schema: adversarial-review/v1
artifact_id: adversarial-2026-07-19-review-presentation-model-cleanup
task_id: skillsbar-review-presentation-model-cleanup-2026-07-19
role: Adversarial Review
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface did not expose an observed child runtime attestation
base_head: eb5bd31
observed_head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: accepted
```

## Independent review scope

I read the Worker packet and handoff, independent QA proof, steering record,
`Package.swift`, the current `DashboardModels.swift`, `ReviewPopoverTests.swift`,
`SkillContractTests.swift`, `DashboardView.swift`, and current Git ownership
state. I did not edit source, tests, the index, packages, application bundles,
or hosted state. This review artifact is the only project-owned write from this
lane.

The Worker handoff SHA-256 is
`cd915557f0844e3cc84d10410b804504ef5c81acfb7ddf2ce1e5833fa05aa51b`.
The QA proof SHA-256 is
`82721d82575034a9801f332685de800e8309afd68136e300aed41cdb6162416d`.

## Disproof attempts and results

### 1. Missed production caller — no finding

The historical model was introduced with private legacy `DashboardView` callers
(`ReviewHeader`, `PackageIdentity`, `ReviewTriggerCard`, `EvidenceBridge`, and
`ReviewAction`). The current source has no `ReviewPresentation` declaration or
consumer under `Sources/SkillsBar`; the active call chain is
`SkillsBarApp -> DashboardView -> ReleaseEvidenceView`.

Command: `zsh -lc 'if rg -n "\\bReviewPresentation\\b" Sources/SkillsBar/Models/DashboardModels.swift Tests/SkillsBarTests/ReviewPopoverTests.swift; then exit 21; else print "PASS: no retired model/test references"; fi'` -> pass (neither canonical retired source nor legacy test file contains the type).

Command: `zsh -lc 'rg -n "DashboardView\\(|ReleaseEvidenceView\\(" Sources/SkillsBar/App/SkillsBarApp.swift Sources/SkillsBar/Support/Snapshot.swift Sources/SkillsBar/Views/DashboardView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift'` -> pass (the app and snapshot route through `DashboardView`, which renders `ReleaseEvidenceView`; the retained test renders `ReleaseEvidenceView` directly).

### 2. Removed tests discarded active semantics — no acceptance-blocking finding

The pre-change source contained 53 test functions; the current file contains
44, matching the nine named retired `ReviewPresentation` test functions. A
bounded diff comparison confirms that the retained assertions are now direct
assertions over active model contracts:

- incomplete quality/impact evidence still asserts `SkillDashboard.score == nil`;
- advisory security still asserts `SecurityDisposition` and `SecuritySignal`
  advisory semantics;
- flagged registry evidence still asserts `TesslSignal.evidenceRequiresReview`.

The deleted properties (`state`, bridge copy, trigger titles/icons, and
presentation-only tones) belonged to the retired private view graph. The active
release view instead reads pipeline receipts, `security.severityLine`, and the
Tessl signal directly.

Command: `zsh -lc 'if rg -n "testReviewPresentationExplainsLocalAndRegistryTruth|testPendingPresentationDoesNotClaimReviewOrSuccess|testHealthyPresentationUsesPositiveSemantics|testUnavailableRegistryDoesNotRenderSuccessBridge|testLocalAdvisoryPresentationIsBlueAndNotHealthy|testSecurityFindingOutranksMissingQualityAndImpactScores|testFailedSecurityUsesDangerTone|testLowLocalScoreIsNotPresentedAsHealthy|testRegistryFindingIsNotDescribedAsClean" Tests/SkillsBarTests/ReviewPopoverTests.swift; then exit 22; else print "PASS: all nine retired tests absent"; fi'` -> pass (all nine named retired functions absent).

### 3. Two-file source-contract guard — no finding

`testRetiredReviewPresentationIsAbsentFromModelAndLegacyTests` independently
loads both `DashboardModels.swift` and `ReviewPopoverTests.swift` and has one
negative assertion for each. It is intentionally type-specific: a future
unrelated test may remain, but the specific retired model cannot be restored in
either canonical file without failing the maintained SwiftPM target. That is
proportionate to this cleanup and avoids a brittle permanent list of historical
test names.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (4 tests, 0 failures; includes the two-file retired-type absence guard).

### 4. Alternate type, duplicate, or orphan — no finding

The complete current-tree search found only the guard method and its two literal
checks. The only production `*Presentation` declaration found is
`RegistryMetricPresentation`, which is actively consumed by the Tessl evidence
card. No duplicate review-state/bridge type or unreferenced retained
`ReviewPresentation` symbol was found.

Command: `zsh -lc 'rg -n -i "ReviewPresentation|review presentation" . --glob "!\.git/**" --glob "!\.build/**"'` -> pass (only the focused contract guard remains).

### 5. Preserved visual lane — no finding

The staged implementation screenshot and staged `ReleaseEvidenceView.swift`
remain staged only. This cleanup added no unstaged diff to either path.

Command: `zsh -lc 'if git diff --name-only -- .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png Sources/SkillsBar/Views/ReleaseEvidenceView.swift | rg .; then exit 23; else print "PASS: no unstaged slice edit to preserved staged paths"; fi'` -> pass (the cleanup made no unstaged edit to either preserved path).

Command: `git diff --cached --name-status -- .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png Sources/SkillsBar/Views/ReleaseEvidenceView.swift` -> pass (both paths remain staged as pre-existing visual work).

Command: `git diff --check` -> pass (no whitespace diagnostics in the current worktree diff).

## Findings

No severity-ranked acceptance-blocking finding was reproduced.

| Severity | Finding | Disposition |
|---|---|---|
| informational | The permanent guard is intentionally type-specific and does not maintain a brittle deny-list of the nine old test names. The bounded source probe confirms those names are currently absent. | accepted; no change recommended |

## Verdict and claims boundary

Verdict: **accepted** for the narrow `ReviewPresentation` model/test cleanup.

This adversarial lane proves only that the current canonical production and
legacy-test files no longer contain the retired type, the named nine historical
tests are absent, retained active model checks remain, the focused contract test
executes green, and the cleanup added no unstaged edit to the staged visual
baseline or `ReleaseEvidenceView.swift`.

It does not prove `ReviewPopoverTests` snapshot equivalence, full-suite status,
live MenuBarExtra behaviour, installed bundle state, Tessl/registry truth,
hosted CI or review, signing, notarization, publication, or release readiness.

WROTE: .harness/reviews/2026-07-19-review-presentation-model-cleanup-adversarial.md
