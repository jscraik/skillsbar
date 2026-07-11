# SkillsBar pipeline-posture validation QA proof

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-11-skillsbar-pipeline-posture-validation
date: 2026-07-11
canonical_title: QA-Worker-SkillsBar Pipeline Posture Validation
qa_lane: validation-only
runtime_profile:
  requested: gpt-5.6-luna/high
  verified: false
prior_repair_qa: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-repair-qa.md
repair_worker_handoff: .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md
strategy_receipt: .harness/reports/2026-07-10-skillsbar-pipeline-posture-strategy-change.md
qa_result: accepted_focused_xctest
selected_tests: 5
failures: 0
```

## Verdict

Accepted within the focused validation boundary. The canonical SwiftPM/XCTest
shape built the current dirty source and executed all five requested regression
tests. Each passed. This supplies the execution proof missing from the prior
repair Worker handoff and repair QA proof; it is consistent with their
source/parser-backed acceptance of the candidate-fingerprint and interpolated
guidance repairs.

The run emitted non-fatal SwiftPM user-cache permission warnings and Xcode
FSEvents warnings, but it completed in 18.4 seconds overall, built in 8.91
seconds, and executed five selected tests with zero failures in 0.009 seconds.
No `test_runtime_blocked` classification or strategy change is required for
this run.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-validation-qa-home XDG_CACHE_HOME=/private/tmp/skillsbar-validation-qa-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-validation-qa-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer /opt/homebrew/bin/timeout --signal=TERM --kill-after=10 180 swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-validation-qa-test-build -Xswiftc -gnone --filter 'ReviewPopoverTests/(testLoaderRejectsEvidenceWhenGovernedInputChangesDuringCollection|testFirstActiveStageAfterSecurityPassesHasInterpolatedGuidance|testPipelinePostureReconcilesVisibleFixtureContributions|testPipelineGatesLaterReceiptsAfterReviewStage|testHistoricalTesslDataDoesNotChangeLocalPipelinePosture)'` -> pass (SwiftPM built the current dirty source, then XCTest executed all five selected tests with 0 failures and 0 unexpected failures; the bounded timeout did not fire.)

## Reconciliation with prior repair QA

- Candidate mutation during evidence collection is now covered by an executed
  regression: stale baseline/security evidence cannot contribute to the newer
  candidate and later stages remain unproven.
- The first active later stage now has executed coverage for interpolated,
  stage-specific guidance.
- The approved visible fixture contributions, sequential review-stage gating,
  and separation of historical Tessl data from local posture arithmetic each
  have fresh focused execution proof.
- The prior repair QA's source/parser acceptance is therefore supplemented by
  current focused XCTest execution. This result does not widen that QA's
  product or delivery claims.

## Remaining boundaries

This proof does not establish the result of the complete SwiftPM test suite,
live `MenuBarExtra` rendering or interaction, snapshot fidelity, clipboard,
focus, reduced-motion, accessibility, or popover-height behavior. It does not
prove `NO_OPEN=1 ./Launch.command`, live launch verification, packaging,
signing, notarization, Tessl authentication or freshness, hosted CI, review
state, commit, push, publication, merge, or release readiness.

The lane inspected the current dirty diff and accepted repair artifacts. It did
not edit source or specifications, reconcile unrelated dirty files, package,
sign, notarize, publish, stage, commit, push, or mutate external state.

WROTE: .harness/reports/qa-proofs/2026-07-11-skillsbar-pipeline-posture-validation-qa.md
