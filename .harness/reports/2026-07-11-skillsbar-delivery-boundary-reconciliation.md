# SkillsBar delivery-boundary reconciliation

```yaml
schema: delivery-boundary-reconciliation/v1
artifact_id: pm-2026-07-11-skillsbar-delivery-boundary
date: 2026-07-11
project: SkillsBar
branch: codex/review-popover-delivery
observed_head: 2c85cb8d4286ecab935610e29f77ac155d704065
observed_upstream: origin/codex/review-popover-delivery
upstream_delta: ahead_0_behind_0
worktree_before_receipt: clean
decision: blocked_external_commit_boundary
```

## Reconciliation result

The previously dirty worktree was committed outside this PM turn before the
authorized reconciliation could stage an explicit delivery set. Commit
`2c85cb8d4286ecab935610e29f77ac155d704065` is also the current upstream tip.
It combines the independently QA-accepted pipeline implementation and governed
proof with PM-only design evidence and files whose ownership was previously
unproven. The authorization condition requiring a commit set composed solely
of accepted implementation and required proof is therefore not satisfied.

## File-by-file classification

### A. Accepted pipeline implementation

- `Sources/SkillsBar/Models/DashboardModels.swift`
- `Sources/SkillsBar/Services/DashboardLoader.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `Tests/SkillsBarTests/ReviewPopoverTests.swift`

These are the implementation/test paths named by the original Worker handoff,
the bounded repair handoff, and the accepted focused-XCTest QA proof.

### B. Required durable Worker/QA proof

- `.harness/reports/2026-07-10-skillsbar-pipeline-posture-strategy-change.md`
- `.harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-worker.md`
- `.harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md`
- `.harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md`
- `.harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-repair-qa.md`
- `.harness/reports/qa-proofs/2026-07-11-skillsbar-pipeline-posture-validation-qa.md`

### C. PM-only design/mockup evidence

- `.harness/media/2026-07-10-skillsbar-pipeline-posture-approved.png`
- `.harness/specs/2026-07-10-skillsbar-pipeline-posture-spec.md`
- `Assets/Concepts/skillsbar-icon-concept-v2.png`

These paths support the approved design direction but were not part of the
independently QA-accepted implementation/repair file set.

### D. Unrelated or unowned preserved state

- `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md`
- `Sources/SkillsBar/Support/Snapshot.swift`
- `script/package_app.sh`
- `.codex/skills/improve-animations/AUDIT.md`
- `.codex/skills/improve-animations/PLAN-TEMPLATE.md`
- `.codex/skills/improve-animations/SKILL.md`

The first three paths were explicitly treated as preserved or not proven
Worker-owned during admission. The project-local `improve-animations` skill
paths were not present in the reconciled dirty inventory and have no linkage to
the accepted pipeline Worker/QA artifacts.

## Proposed commit set

Had the dirty state still existed, the authorized narrow commit set would have
been categories A and B only:

- `Sources/SkillsBar/Models/DashboardModels.swift`
- `Sources/SkillsBar/Services/DashboardLoader.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `Tests/SkillsBarTests/ReviewPopoverTests.swift`
- `.harness/reports/2026-07-10-skillsbar-pipeline-posture-strategy-change.md`
- `.harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-worker.md`
- `.harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md`
- `.harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md`
- `.harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-repair-qa.md`
- `.harness/reports/qa-proofs/2026-07-11-skillsbar-pipeline-posture-validation-qa.md`

No new commit is authorized from the current state because HEAD already mixes
categories A through D and is present at the upstream tip.

## Evidence

Command: `git status --porcelain=v2 --branch` -> pass (before writing this receipt, the worktree was clean; HEAD was `2c85cb8d4286ecab935610e29f77ac155d704065`, tracking `origin/codex/review-popover-delivery` at ahead 0 and behind 0.)

Command: `git show --name-status --format=fuller HEAD` -> pass (the current commit contains all 19 paths classified above, including accepted implementation, governed proof, PM-only evidence, and previously unowned state.)

Command: `git rev-list --left-right --count HEAD...@{upstream}` -> pass (returned `0 0`; the mixed commit is already the tracked upstream tip.)

Validation: not run (the commit-scope precondition failed before validation: the already-published HEAD contains PM-only and unowned paths, so focused tests and `git diff --check` could not authorize the requested narrow commit.)

## Chief decision required

Choose whether to accept commit `2c85cb8d4286ecab935610e29f77ac155d704065`
as an intentionally broad delivery unit, or authorize a non-history-rewriting
corrective follow-up that removes or relocates categories C and D. Rewriting or
force-pushing the published commit is not inferred or authorized.

## Claims boundary

This receipt classifies commit scope and records the external-state blocker. It
does not validate the broad commit, approve PM-only or unowned files for
delivery, alter published history, clean the worktree, stage files, create a
commit, push, package, or establish live-UI or release readiness.
