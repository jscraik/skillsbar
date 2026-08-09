---
schema_version: pm-child-task-packet/v1
task_id: skillsbar-review-presentation-model-cleanup-2026-07-19
project: SkillsBar
role: Worker
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface does not expose an observed child runtime attestation
base_head: eb5bd31
authority: explicit user approval for a separate TDD cleanup of ReviewPresentation and its legacy-only tests
---

# Worker packet — ReviewPresentation model cleanup

## Objective

Characterize and remove the now-unreferenced `ReviewPresentation` production
model and only the legacy test functions that construct it. Preserve the active
nine-gate implementation, snapshot lane, and staged work exactly.

## Allowed canonical files

- `Sources/SkillsBar/Models/DashboardModels.swift`
- `Tests/SkillsBarTests/ReviewPopoverTests.swift`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `.harness/steering-feedback/2026-07-19-legacy-review-presentation-cleanup.json`
- `.harness/reports/worker-handoffs/2026-07-19-review-presentation-model-cleanup-worker.md`

## Preserve without modification

- every existing staged path, including `ReleaseEvidenceView.swift` and
  `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- the existing unstaged UI-route/legacy-view cleanup in `AGENTS.md`, README,
  `DashboardView.swift`, and `SkillContractTests.swift` except for the single
  addition required by this packet
- `.codex/skills/find-animation-opportunities/`
- app bundles, build caches, packaging, launch, registry, hosted, signing,
  and release state

## Caller map and invariants

- `ReviewPresentation` is declared in `DashboardModels.swift`.
- The bounded source search currently finds no production consumer under
  `Sources/SkillsBar`.
- `ReviewPopoverTests.swift` contains the retained legacy test functions that
  construct it. Do not remove unrelated model/dashboard, fixture, rendering,
  accessibility, registry, or snapshot tests.
- The active app remains `DashboardView` -> `ReleaseEvidenceView`.

## Required TDD sequence

1. Re-run and record a bounded caller map before edits: declaration, source
   consumers, and each test construction.
2. Add one focused `SkillContractTests` source-contract assertion that fails
   while `ReviewPresentation` remains in either `DashboardModels.swift` or
   `ReviewPopoverTests.swift`. Run the exact focused command and record its
   expected red result.
3. Remove the model and only the whole test functions whose purpose is to
   exercise that retired model. If a test combines active dashboard behaviour
   with the retired presentation, retain the active assertions in a suitable
   existing test rather than discarding them.
4. Run the exact focused command green. The target compiles the full test
   target, so compilation validates references across the retained test source.
5. Run bounded source searches proving zero production and legacy-test
   references, update the steering record to `implemented` with actual proof,
   and run `git diff --check`.
6. Write the required Worker handoff with caller map, removed test names,
   red/green evidence, preservation boundary, residual risk, and claims
   boundary. End exactly:
   `WROTE: .harness/reports/worker-handoffs/2026-07-19-review-presentation-model-cleanup-worker.md`

## Stop conditions

- A source caller outside the retired graph exists.
- A candidate test function contains active assertions that cannot be retained
  without an unapproved behavioural decision.
- The focus test cannot compile due to staged visual/snapshot work or a
  toolchain/runtime blocker.
- The cleanup requires edits outside the allowed files.

## Validation boundary

Run only the isolated `SkillContractTests` command and source/diff checks.
Do not rerun `ReviewPopoverTests`: its visual snapshot mismatch is staged,
separate, and out of scope. Do not package, launch, publish, or stage.

## Claims boundary

The task can prove the source/test cleanup and focused local compile lane. It
cannot prove snapshot equivalence, full suite, live MenuBarExtra behaviour,
installed bundle, Tessl/registry, hosted checks/review, signing, notarization,
publication, or release readiness.
