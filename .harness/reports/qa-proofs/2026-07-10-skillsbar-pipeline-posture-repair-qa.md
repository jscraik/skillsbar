# SkillsBar pipeline-posture repair QA proof

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-10-skillsbar-pipeline-posture-repair
date: 2026-07-10
qa_lane: independent-disproof
canonical_title: QA-Worker-SkillsBar Pipeline Posture Repair
human_task_name: Independently disprove or accept the candidate-fingerprint repair
strategy_receipt: .harness/reports/2026-07-10-skillsbar-pipeline-posture-strategy-change.md
original_qa_proof: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md
product_contract: .harness/specs/2026-07-10-skillsbar-pipeline-posture-spec.md
inspected_repair_scope:
  - Sources/SkillsBar/Services/DashboardLoader.swift
  - Tests/SkillsBarTests/ReviewPopoverTests.swift
necessary_call_sites:
  - Sources/SkillsBar/Models/DashboardModels.swift
  - Sources/SkillsBar/Views/DashboardView.swift
qa_result: accepted
```

## Claims boundary

This independent QA lane inspected the actual uncommitted repair and adjacent
model/view call sites. It accepted the three requested source-state claims
using source tracing, focused regression-test inspection, direct Swift parser
validation, and whitespace validation.

The focused SwiftPM run did not complete: it reached source compilation and
then produced no further output during the bounded observation window. QA
interrupted it and classified it as an environment/tooling stall, as required
by the packet. Therefore this proof does **not** claim that the current repaired
test binary executed. Direct parser success proves syntax only; source tracing
proves the implemented control/data-flow shape but does not reproduce real
package/security subprocess timing under a live app session.

This QA lane did not prove live `MenuBarExtra` rendering, clipboard or keyboard
interaction, accessibility behavior, Tessl authentication or registry
freshness, packaging, signing, notarization, hosted CI/review state, commit
state, publication, or release readiness. It did not edit application source,
stage, commit, push, publish, or change external state.

## Severity-ranked findings

No actionable implementation findings. The prior HIGH candidate-fingerprint
defect and MEDIUM literal-guidance defect are repaired within the inspected
source boundary.

### BLOCKED VALIDATION — QA-V001: focused SwiftPM execution stalled during compilation

- **Severity:** validation blocker; not an implementation defect.
- **Ownership:** environment/tooling.
- **Evidence:** the focused command emitted SwiftPM cache-permission warnings,
  progressed through resource copying and `SkillsBarCore` compilation, then
  remained quiet without completing or launching the selected tests. QA
  interrupted it with exit code `130` after a bounded wait.
- **Remediation:** rerun the same focused filter from a normal local toolchain
  session or after the stalled compiler/process condition is cleared. Do not
  reinterpret this interrupted run as a product-test failure.
- **Does not prove:** it does not prove that any selected current-repair XCTest
  passed or failed.

## Claim-by-claim disproof

### 1. Evidence collected for an older candidate cannot certify a newer candidate

**Result: accepted.**

- The asynchronous production path enters `collectEvidenceAsync` before
  launching package, scenario, and security collection
  (`Sources/SkillsBar/Services/DashboardLoader.swift:106-114`). The helper
  captures the governed-input fingerprint before awaiting the collection and
  returns that original fingerprint with the evidence (`:295-305`).
- The synchronous production path applies the same boundary around its three
  evidence commands (`Sources/SkillsBar/Services/DashboardLoader.swift:157-163`)
  through `collectEvidence`, whose fingerprint argument is evaluated before
  the collection closure (`:284-292`).
- After collection, `pipelineCandidate` re-enumerates the governed inputs and
  recomputes the current candidate fingerprint
  (`Sources/SkillsBar/Services/DashboardLoader.swift:196-208`). Baseline and
  security receipts keep the **pre-collection** evidence fingerprint
  (`:232-249`), rather than being stamped with the recomputed candidate value.
- `PipelineCandidate.gatedReceipts` converts each mismatched receipt to
  `.stale` (`Sources/SkillsBar/Models/DashboardModels.swift:212-233`), and
  `contribution(for:)` returns zero unless the receipt fingerprint equals the
  candidate fingerprint and the receipt is current (`:203-209`). Once the
  baseline is stale, later receipts are held unproven by sequential gating
  (`:234-250`).
- The new controlled regression changes `SKILL.md` inside the evidence
  collection boundary, asserts different before/after fingerprints, asserts
  stale baseline/security receipts, asserts later unproven stages, and asserts
  zero evidenced stages and zero posture
  (`Tests/SkillsBarTests/ReviewPopoverTests.swift:398-450`).

**Disproof attempt:** QA traced both `load()` and `loadSync()` looking for a path
that starts evidence before the first fingerprint or stamps evidence with only
the later fingerprint. No such current path was found.

**What this evidence does not prove:** the controlled regression was inspected
but could not be executed in the current QA window because SwiftPM stalled. It
does not establish an atomic filesystem snapshot if files change while a
fingerprint itself is being read; that stronger guarantee is outside the
approved repair contract.

### 2. The first active later stage has stage-specific guidance, not a literal Swift expression

**Result: accepted.**

- `unprovenReceipt` now uses real Swift interpolation:
  `"Establish current \(stage.title.lowercased()) evidence after earlier stages pass."`
  (`Sources/SkillsBar/Services/DashboardLoader.swift:266-281`).
- `PipelineCandidate.activeReceipt` selects the first receipt that has not
  passed (`Sources/SkillsBar/Models/DashboardModels.swift:193-195`), and the
  visible next-action surface renders that receipt's `nextAction` directly
  (`Sources/SkillsBar/Views/DashboardView.swift:245-275`).
- The focused regression establishes passing baseline/security evidence,
  asserts that `ossLocal` is active, asserts the exact rendered model guidance
  `Establish current oss-local proof evidence after earlier stages pass.`, and
  rejects the old literal token (`Tests/SkillsBarTests/ReviewPopoverTests.swift:453-494`).

**Disproof attempt:** QA searched the source/test surface for the prior
non-interpolated literal. Matches now occur only inside valid interpolation or
the negative regression assertion; no user-visible literal construction was
found.

**What this evidence does not prove:** parser/source evidence does not prove a
live pixel rendering or accessibility announcement of the text.

### 3. Score arithmetic, sequential gating, custom icons, and Tessl exclusion are not regressed

**Result: accepted.**

- Stage weights remain exactly `15, 25, 20, 20, 10, 10`
  (`Sources/SkillsBar/Models/DashboardModels.swift:86-113`). Current contribution
  remains `round(weight * clampedScore / 100)`, and posture remains the sum of
  those receipt contributions (`:183-210`). The fixture regression still
  asserts `[15, 9, 0, 0, 0, 0]` and posture `24`
  (`Tests/SkillsBarTests/ReviewPopoverTests.swift:333-343`).
- Sequential gating remains ordered by `PipelineStage.allCases`; after the first
  non-passing stage, later matching receipts are rewritten as unproven with no
  score (`Sources/SkillsBar/Models/DashboardModels.swift:212-250`). The focused
  gating regression remains at
  `Tests/SkillsBarTests/ReviewPopoverTests.swift:345-370`.
- The header and historical card still call `SkillsSDKLogoView` and
  `TesslLogoView` (`Sources/SkillsBar/Views/DashboardView.swift:45-54,190-196`).
  Their loaders resolve the packaged `SkillsSDKIcon.png` and `TesslLogo.png`
  resources (`:833-881,941-963`); both resource files exist in the inspected
  checkout.
- The local header reads only `candidate.postureScore`
  (`Sources/SkillsBar/Views/DashboardView.swift:72-88`). The Tessl card remains
  a later secondary surface, retains Quality/Impact/Security/lift language, and
  renders the historical-not-proof disclaimer (`:190-242`). Tessl mutations
  remain outside `PipelineCandidate` arithmetic, and the regression asserts
  that changing all Tessl metrics leaves local posture at `24`
  (`Tests/SkillsBarTests/ReviewPopoverTests.swift:497-507`).

**Disproof attempt:** QA searched the current model and view for changed weights,
later-stage early credit, generic icon substitution, or Tessl fields feeding
`postureScore`. No regression path was found.

**What this evidence does not prove:** the current SwiftPM stall prevented fresh
execution of the arithmetic/gating/Tessl regressions and prevented fresh
snapshot or live UI evidence.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-repair-qa-home XDG_CACHE_HOME=/private/tmp/skillsbar-repair-qa-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-repair-qa-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-repair-qa-test-build -Xswiftc -gnone --filter "ReviewPopoverTests/(testLoaderRejectsEvidenceWhenGovernedInputChangesDuringCollection|testFirstActiveStageAfterSecurityPassesHasInterpolatedGuidance|testPipelinePostureReconcilesVisibleFixtureContributions|testPipelineGatesLaterReceiptsAfterReviewStage|testHistoricalTesslDataDoesNotChangeLocalPipelinePosture)"` -> blocked (environment/tooling: SwiftPM reached source compilation, then made no further progress during the bounded observation window; QA interrupted it with exit code 130. No selected test outcome is claimed.)

Command: `DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer /usr/bin/xcrun swiftc -frontend -parse Sources/SkillsBar/Services/DashboardLoader.swift Sources/SkillsBar/Models/DashboardModels.swift Sources/SkillsBar/Views/DashboardView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift` -> pass (the repaired loader and its model, view, and regression-test call sites parse successfully; syntax proof only.)

Command: `git diff --check` -> pass (no whitespace diagnostics in the inspected worktree diff.)

Command: `rg -n -F "(stage.title.lowercased())" Sources/SkillsBar Tests/SkillsBarTests` -> pass (the token appears only within valid Swift interpolation and the negative regression assertion; no old non-interpolated user-visible string remains.)

## QA decision

**Accepted within the stated claims boundary.** The repair binds evidence to a
pre-collection fingerprint, recomputes the candidate fingerprint after
collection, and lets existing model gating turn changed-run evidence stale or
unproven with zero contribution. Later-stage guidance is interpolated and
stage-specific. The existing weight arithmetic, sequential gating, custom icon
loaders, and historical Tessl exclusion remain intact in the inspected source.

Fresh XCTest execution remains blocked by an environment/tooling stall, so this
acceptance is source/parser-backed and must not be promoted into live app,
packaging, hosted, Tessl, or release proof.

WROTE: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-repair-qa.md
