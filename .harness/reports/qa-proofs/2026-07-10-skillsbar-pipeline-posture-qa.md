# SkillsBar pipeline-posture QA proof

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-10-skillsbar-pipeline-posture
date: 2026-07-10
qa_lane: independent-disproof
worker_handoff: .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-worker.md
product_contract: .harness/specs/2026-07-10-skillsbar-pipeline-posture-spec.md
worker_owned_scope:
  - Sources/SkillsBar/Models/DashboardModels.swift
  - Sources/SkillsBar/Services/DashboardLoader.swift
  - Sources/SkillsBar/Views/DashboardView.swift
  - Tests/SkillsBarTests/ReviewPopoverTests.swift
qa_result: rejected
```

## Claims boundary

This QA lane inspected the actual uncommitted Worker output, its declared
handoff, and the successor pipeline-posture contract. It tested source/model
behavior and deterministic SwiftUI rendering only. It did not run a live
`MenuBarExtra` session or mutate application source, Tessl, packaging, release,
or hosted state.

## Severity-ranked findings

### HIGH — QA-001: current fingerprints can certify evidence collected for an older candidate

- **Status:** rejected claim 2 / AC-001 evidence boundary.
- **Ownership:** introduced by current patch.
- **Evidence:** `DashboardLoader.load()` starts package, scenario, and security
  commands at `Sources/SkillsBar/Services/DashboardLoader.swift:99-101`, awaits
  their outputs at `:104-110`, and only then invokes `pipelineCandidate` at
  `:127-132`. `pipelineCandidate` reads governed inputs and computes the
  fingerprint at `:185-189`, then stamps that just-computed fingerprint onto
  the current baseline and security receipts at `:208-234`.
- **Reproduction condition:** change `SKILL.md` or another governed input after
  an evidence command starts but before `pipelineCandidate` reads the files.
  The command result was produced for the old candidate, yet the post-change
  fingerprint is written into the receipt. `PipelineCandidate.isCurrent` then
  accepts that receipt solely because it equals the just-written fingerprint
  (`Sources/SkillsBar/Models/DashboardModels.swift:203-209`) and gives it a
  non-zero contribution.
- **Impact:** a changed governed input does not reliably supersede active
  package/security proof. The pipeline can display a current, non-zero local
  posture for stale evidence, which defeats the primary candidate-truth
  contract.
- **Coverage gap:**
  `ReviewPopoverTests.testFingerprintChangeMakesOldReceiptsStale` only creates
  already-mismatched synthetic receipts
  (`Tests/SkillsBarTests/ReviewPopoverTests.swift:372-395`); it does not
  exercise the loader ordering above. It therefore passes while the real
  collection-to-fingerprint race remains.
- **Remediation direction:** bind each evidence run to a fingerprint captured
  before it starts, recompute after the run, and accept the receipt only when
  both fingerprints match. Otherwise make the stage unproven/stale and trigger
  a new collection for the changed candidate. Add a loader-level regression
  test that changes a governed fixture during a controlled evidence run.

### MEDIUM — QA-002: later-stage next action renders a literal Swift expression

- **Status:** rejected clear-next-action behavior after an earlier stage passes.
- **Ownership:** introduced by current patch.
- **Evidence:** the helper constructs its next action as the non-interpolated
  string `"Establish current (stage.title.lowercased()) evidence after earlier
  stages pass."` at
  `Sources/SkillsBar/Services/DashboardLoader.swift:247-262`. When, for
  example, baseline and security have passed, `oss-local` becomes the active
  unproven stage and `PipelineAction` displays `receipt.nextAction` directly at
  `Sources/SkillsBar/Views/DashboardView.swift:270-275`.
- **Impact:** the user sees the literal text
  `(stage.title.lowercased())` instead of the stage-specific inspection
  guidance required to make the active blocker obvious.
- **Remediation direction:** use Swift string interpolation and add an
  assertion for the first active unproven stage after security passes.

## Claim-by-claim disproof results

| Claim | Result | Actual-output evidence |
| --- | --- | --- |
| 1. Six weights are `15,25,20,20,10,10`; visible contributions reconcile with the header. | **Accepted** | `PipelineStage.weight` supplies exactly those values (`Sources/SkillsBar/Models/DashboardModels.swift:86-115`). The posture is the sum of rounded current contributions (`:183-210`); the header uses that same `candidate.postureScore` and `evidencedStageCount` (`Sources/SkillsBar/Views/DashboardView.swift:72-88`), while rows render the same contribution passed into the row (`:130-186`). The fixture test asserts `[15, 9, 0, 0, 0, 0] = 24` (`Tests/SkillsBarTests/ReviewPopoverTests.swift:333-343`). |
| 2. Governed-input changes invalidate prior receipts; stale/unproven stages do not contribute. | **Rejected** | The model returns zero for mismatched, stale, and unproven receipts (`Sources/SkillsBar/Models/DashboardModels.swift:203-248`), but QA-001 shows the loader can incorrectly attach old command output to a new fingerprint. The claim is not true for actual asynchronous or synchronous collection. |
| 3. Security blocks later `oss`/Tessl/runtime stages without fabricating scenario-quality evidence. | **Accepted, subject to QA-001** | The loader maps only package and security results to current receipts (`Sources/SkillsBar/Services/DashboardLoader.swift:208-238`); it creates the four later stages as unproven (`:239-262`) despite separately obtaining scenario-quality. The gated model turns later supplied receipts unproven after a non-passing earlier receipt (`Sources/SkillsBar/Models/DashboardModels.swift:212-250`), covered by `testPipelineGatesLaterReceiptsAfterReviewStage` (`Tests/SkillsBarTests/ReviewPopoverTests.swift:345-370`). |
| 4. Historical Tessl is secondary, retains the custom asset/product score language, and cannot affect local posture. | **Accepted** | The view places the pipeline before `HistoricalTesslCard` (`Sources/SkillsBar/Views/DashboardView.swift:18-30`); the card uses `TesslLogoView`, the Tessl score/Quality/Impact/Security/lift language, and the exact historical-not-proof disclaimer (`:190-242`). `postureScore` only reduces pipeline receipts (`Sources/SkillsBar/Models/DashboardModels.swift:183-210`), and `testHistoricalTesslDataDoesNotChangeLocalPipelinePosture` passes (`Tests/SkillsBarTests/ReviewPopoverTests.swift:398-409`). |
| 5. Skills SDK custom icon is retained; active stage has one full-copy command with unified accessible/copy semantics. | **Accepted** | The packaged `Sources/SkillsBar/Resources/SkillsSDKIcon.png` is used by `SkillsSDKLogoView` (`Sources/SkillsBar/Views/DashboardView.swift:833-855`). The active receipt supplies one `command` value; `PipelineAction` uses that same value for button copy and command preview/accessibility value (`:245-305`). Its button has an explicit accessible label and tooltip (`:278-291`). |
| 6. Snapshot evidence does not overclaim live menu-bar, clipboard, keyboard, motion, or visible-frame behavior. | **Accepted** | The worker handoff explicitly excludes those live claims (`.harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-worker.md:74-85`). The renderer creates an isolated `NSHostingView` at the fixed template size (`Sources/SkillsBar/Support/Snapshot.swift:67-87`), and tests assert only 404x720 pixels (`Tests/SkillsBarTests/ReviewPopoverTests.swift:274-314`). No live UI verification was claimed or run in this QA lane. |
| 7. dSYM and full no-debug test outcomes are correctly classified. | **Accepted with provenance limit** | QA independently reproduced the canonical `generate-dSYM` `Operation not permitted` stop after source compilation; this is an environment/tooling blocker, not a product-test outcome. The full no-debug suite reached all 34 `ReviewPopoverTests` successfully, then failed two assertions in unchanged `Tests/SkillsBarCoreTests/ShellTests.swift:23,25` (`3000110` actual vs `3000000` expected). That supports classification as unrelated to the Worker patch; this QA run does not independently establish when the Shell failure first existed. |

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-qa-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-qa-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-qa-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-qa-test-build-no-debug -Xswiftc -gnone --filter ReviewPopoverTests` -> pass (34 `ReviewPopoverTests` passed, including fixture arithmetic, security gating, Tessl exclusion, deterministic rendering, and injected-pasteboard behavior; does not exercise the loader fingerprint timing race.)

Command: `HOME=/private/tmp/skillsbar-qa-canonical-home XDG_CACHE_HOME=/private/tmp/skillsbar-qa-canonical-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-qa-canonical-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-qa-canonical-test-build` -> blocked (`generate-dSYM` exited 1 with `Operation not permitted` after the Worker sources compiled; the test executable did not run.)

Command: `HOME=/private/tmp/skillsbar-qa-full-home XDG_CACHE_HOME=/private/tmp/skillsbar-qa-full-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-qa-full-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-qa-full-test-build-no-debug -Xswiftc -gnone` -> fail (34 `ReviewPopoverTests` passed; `SkillsBarCoreTests.ShellTests.testRunCapturesLargeStdoutAndStderrWithoutDeadlock` failed two assertions because `3000110 != 3000000`.)

Command: `git diff --check` -> pass (no whitespace diagnostics in the inspected worktree.)

## QA decision

**Rejected.** The visual hierarchy, score arithmetic, later-stage non-fabrication,
Tessl separation, copy-source unification, evidence wording, and validation
classification hold within the exercised boundaries. QA-001 is a high-severity
candidate-integrity defect: the implementation cannot truthfully claim that a
governed-input change invalidates evidence when that change occurs while local
checks are running. QA-002 is a separate user-visible active-action defect.

WROTE: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md
