# SkillsBar pipeline-posture worker handoff (historical)

> Superseded by `.harness/reports/2026-07-14-skillsbar-nine-gate-ui-validation.md#pr-2-follow-up-validation`.
> Retained as historical provenance; do not use this receipt as current
> candidate proof.

## Changed files

- `Sources/SkillsBar/Models/DashboardModels.swift`
  - Added explicit `PipelineCandidate`, `PipelineStageReceipt`, ordered
    `PipelineStage`, evidence status, governed-input fingerprint, current
    contribution arithmetic, and downstream gating.
  - Added the deterministic review fixture with candidate baseline `15` and
    security-review `9` contributions for pipeline posture `24`.
- `Sources/SkillsBar/Services/DashboardLoader.swift`
  - Hashes `SKILL.md` plus governed reference, scenario, criteria, rubric,
    scorer, model, and eval inputs for the selected local skill.
  - Maps only package verification and security review into current local
    receipts. It deliberately leaves `oss-local`, `oss-cloud`, Tessl staging,
    and live score/runtime unproven; scenario-quality is not used to fabricate
    either oss receipt.
- `Sources/SkillsBar/Views/DashboardView.swift`
  - Replaced the default review-score surface with the six-stage pipeline,
    reconciled posture hex, current-stage-owned icon-only copy action, and
    secondary historical Tessl panel.
  - Retains the Skills SDK and Tessl image assets. The Tessl panel says exactly
    `Historical registry baseline - not proof for current local candidate.`
    and its score/metrics/lift never enter posture arithmetic.
- `Tests/SkillsBarTests/ReviewPopoverTests.swift`
  - Added deterministic arithmetic, order/gating, fingerprint stale-receipt,
    Tessl-exclusion, and pipeline fixture assertions.
  - Replaced the superseded 2026-07-09 pixel-baseline comparison with a stable
    404x720 pipeline renderer check because the renderer was intentionally
    changed for the approved successor visual.

## Branch, HEAD, and dirty state

- Branch: `codex/review-popover-delivery`
- Starting/current HEAD inspected: `a1ab08d7e12a49f9b871526d95efcbf75ad1d01b`
- Worker-owned modified files: the four source/test files above plus this
  handoff.
- Preserved unowned state: modified
  `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md`,
  untracked approved successor spec/media, and untracked `Assets/` including
  `Assets/Concepts/skillsbar-icon-concept-v2.png`. None was overwritten,
  staged, or incorporated as app runtime evidence.

## Validation

Command: `HOME=/private/tmp/skillsbar-home XDG_CACHE_HOME=/private/tmp/skillsbar-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build` -> blocked (`generate-dSYM` ended with `Operation not permitted` after SkillsBar sources compiled and linked was attempted.)

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build` -> blocked (`generate-dSYM` ended with `Operation not permitted` before the test bundle could run.)

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build-no-debug -Xswiftc -gnone --filter ReviewPopoverTests` -> pass (34 ReviewPopoverTests passed, including all pipeline posture and snapshot-canvas checks.)

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build-no-debug -Xswiftc -gnone` -> fail (the new pipeline suite passed; pre-existing `SkillsBarCoreTests.ShellTests.testRunCapturesLargeStdoutAndStderrWithoutDeadlock` expected 3,000,000 bytes but observed 3,000,110 and failed two assertions.)

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer SKILLSBAR_REVIEW_FIXTURE=1 swift run --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-snapshot-build -Xswiftc -gnone SkillsBar --snapshot /private/tmp/skillsbar-pipeline-posture.png` -> pass (wrote the deterministic 404x720 pipeline-posture renderer artifact.)

Command: `NO_OPEN=1 ./Launch.command` -> pass (the repository dev-launch script completed without opening a UI session; this is not MenuBarExtra runtime proof.)

Command: `git diff --check` -> pass (no whitespace diagnostics.)

## Deterministic fixture and snapshot evidence

- Fixture: `SkillDashboard.reviewFixture` in
  `Sources/SkillsBar/Models/DashboardModels.swift`.
- Renderer proof path: `/private/tmp/skillsbar-pipeline-posture.png`.
- Test proof: `ReviewPopoverTests.testPipelinePostureReconcilesVisibleFixtureContributions`,
  `testPipelineGatesLaterReceiptsAfterReviewStage`,
  `testFingerprintChangeMakesOldReceiptsStale`,
  `testHistoricalTesslDataDoesNotChangeLocalPipelinePosture`, and
  `testReviewFixtureRendersPipelinePostureAtTheStableCanvasSize`.
- The old `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
  baseline remains untouched because it records the superseded renderer. No
  new committed raster baseline was added in this bounded source/test slice.

## Remaining gaps and proof boundaries

- The snapshot proves deterministic SwiftUI renderer geometry and hierarchy;
  it does not prove live `MenuBarExtra(.window)` launch, clipboard behavior in
  the real menu-bar session, keyboard traversal, reduced-motion behavior, or
  small-screen scrolling in an actual macOS visible frame.
- The fallback test command suppresses debug information only to work around
  the sandbox dSYM permission failure. It does not replace the repository's
  exact canonical test command, which remains blocked in this environment.
- The full fallback suite has a pre-existing Shell test failure unrelated to
  the worker-owned files. No Tessl login, registry freshness, publication,
  hosted CI, review state, or release readiness was checked.

WROTE: .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-worker.md
