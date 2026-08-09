# SkillsBar ReviewPresentation cleanup — independent QA disproof

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-19-review-presentation-model-cleanup
task_id: skillsbar-review-presentation-model-cleanup-2026-07-19
role: QA Disproof
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface does not expose an observed child runtime attestation
base_head: eb5bd31
observed_head: eb5bd317c9db0642b0990c2d51b939f1030107e1
observed_at: 2026-07-19T19:51:05Z
worker_handoff_sha256: cd915557f0844e3cc84d10410b804504ef5c81acfb7ddf2ce1e5833fa05aa51b
verdict: accepted
```

## Independence and preservation boundary

This QA lane did not edit source, tests, Git index, packages, app bundles, or
runtime state. It read the Worker packet and handoff, steering record, package
definition, scoped sources/tests, and Git ownership boundary. The only intended
write from this lane is this QA proof.

The checkout retains pre-existing staged paths:

- `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- `Sources/SkillsBar/Views/ReleaseEvidenceView.swift`
- `Sources/SkillsBarCore/Shell.swift`
- `Tests/SkillsBarCoreTests/ShellTests.swift`

The packet-authorized cleanup paths are unstaged and distinct. `git diff --name-only`
for the preserved visual snapshot and `ReleaseEvidenceView.swift` returned no
unstaged path, while `git diff --cached --name-status` still listed both as
staged. This proves the cleanup did not add a new unstaged change to either
preserved path; it does not reconstruct their pre-Worker bytes.

## Disproof attempts

### 1. Production declaration or caller

Attempt: search all `Sources/SkillsBar` production source for the retired type.

Command: `zsh -lc 'if rg -n "\\bReviewPresentation\\b" Sources/SkillsBar; then exit 21; else print "PASS: no production ReviewPresentation declaration or caller"; fi'` -> pass (no declaration or caller found).

### 2. Legacy `ReviewPopoverTests` construction or retired test functions

Attempt: search the retained legacy test source for the type and each of the
nine named retired-model tests.

Command: `zsh -lc 'if rg -n "\\bReviewPresentation\\b" Tests/SkillsBarTests/ReviewPopoverTests.swift; then exit 22; else print "PASS: no legacy ReviewPopoverTests construction"; fi'` -> pass (no type construction/reference found).

Command: `zsh -lc 'if rg -n "testReviewPresentationExplainsLocalAndRegistryTruth|testPendingPresentationDoesNotClaimReviewOrSuccess|testHealthyPresentationUsesPositiveSemantics|testUnavailableRegistryDoesNotRenderSuccessBridge|testLocalAdvisoryPresentationIsBlueAndNotHealthy|testSecurityFindingOutranksMissingQualityAndImpactScores|testFailedSecurityUsesDangerTone|testLowLocalScoreIsNotPresentedAsHealthy|testRegistryFindingIsNotDescribedAsClean" Tests/SkillsBarTests/ReviewPopoverTests.swift; then exit 23; else print "PASS: nine retired legacy test functions absent"; fi'` -> pass (all nine retired test names absent).

### 3. Source-contract test wiring and two-file failure shape

`Package.swift` declares `SkillsBarTests`, and the isolated SwiftPM test command
selected and executed `SkillContractTests`, including
`testRetiredReviewPresentationIsAbsentFromModelAndLegacyTests`. The test reads
both canonical paths and has independent negative assertions for the model and
legacy test file.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (4 tests executed, 0 failures; the two-file absence guard executed).

The Worker handoff records the expected red execution before deletion, with
both assertions failing. I did not reintroduce the retired string into either
canonical file merely to recreate that red state; that would violate this QA
lane's non-mutation boundary. The current source proves the two independent
assertions are wired and the focused execution proves they run.

### 4. Retained active `SkillDashboard` conditions

Compared the parent revision's retired tests with the current retained tests.
The active-model conditions are preserved directly:

- `testReviewFixtureMatchesImplementationHandoffContract` still creates an
  incomplete `SkillDashboard` and asserts `dashboard.score == nil` when quality
  and impact scores are missing.
- `testSecurityDispositionUsesSeverityFirstPrecedence` still asserts advisory
  disposition and advisory tone on an active `SecuritySignal`.
- `testRegistryMetricTonesFollowActualValues` still asserts a flagged registry
  condition yields `dashboard.tessl.evidenceRequiresReview`.

The deleted assertions against `ReviewPresentation.state`, bridge copy, icons,
and tones are not active-app assertions after the retired model's only
production graph was removed.

Evidence classification: current source plus `git show HEAD:Tests/SkillsBarTests/ReviewPopoverTests.swift` comparison. Outcome: pass (the stated active conditions remain; no active condition was found discarded with the legacy wrapper).

### 5. Diff and visual/snapshot preservation

Command: `zsh -lc 'if git diff --name-only -- .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png Sources/SkillsBar/Views/ReleaseEvidenceView.swift | rg .; then exit 24; else print "PASS: no unstaged edits touch preserved staged visual or ReleaseEvidenceView path"; fi'` -> pass (no unstaged edit in either preserved path).

Command: `git diff --cached --name-status -- .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png Sources/SkillsBar/Views/ReleaseEvidenceView.swift` -> pass (both paths remain staged, consistent with the pre-existing preservation boundary).

Command: `git diff --check` -> pass (no whitespace diagnostics across the current worktree diff).

One initial combined source-check command was blocked by a shell quoting error
(`zsh:11: unmatched "`). It was an invalid QA command shape, not a repository
or patch failure; the corrected bounded checks above exercised the intended
claims separately.

## Ownership and verdict

Verdict: **accepted** for the narrowly approved source/test cleanup.

- The removed `ReviewPresentation` declaration and nine named test functions
  are owned by the current cleanup patch.
- The preserved staged visual baseline and `ReleaseEvidenceView.swift` remain
  an unrelated staged visual lane.
- The skipped `ReviewPopoverTests` execution is an explicit packet boundary:
  that suite has a separately staged snapshot mismatch and cannot be used as
  evidence for this source cleanup without widening into the visual lane.

## Claims boundary

This QA result proves the focused local source/test-cleanup lane: no production
or legacy-test `ReviewPresentation` reference remains, the two-file absence
guard is selected by the maintained SwiftPM test target, the specified active
`SkillDashboard` conditions remain, and the cleanup introduced no unstaged
change to the preserved visual/snapshot paths.

It does not prove visual snapshot equivalence, the complete `ReviewPopoverTests`
suite, a full SwiftPM suite, live MenuBarExtra behaviour, installed-bundle
state, Tessl or registry truth, hosted CI/review, signing, notarization,
publication, or release readiness.

WROTE: .harness/reports/qa-proofs/2026-07-19-review-presentation-model-cleanup-qa.md
