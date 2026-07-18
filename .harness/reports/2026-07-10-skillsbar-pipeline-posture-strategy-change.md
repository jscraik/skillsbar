# SkillsBar pipeline-posture strategy change

```yaml
schema: strategy-change-receipt/v1
artifact_id: pm-recovery-2026-07-10-skillsbar-pipeline-posture
date: 2026-07-10
project: SkillsBar
human_lane_name: Project PM - SkillsBar
qa_proof: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md
qa_decision: rejected
worker_acceptance: withdrawn_for_repair
findings:
  - id: QA-001
    severity: high
    summary: Evidence commands can start for one candidate and be stamped with a later candidate fingerprint.
  - id: QA-002
    severity: medium
    summary: The first active later-stage action displays a literal Swift expression.
strategy_change:
  prior: Synthetic receipt mismatch tests established model invalidation but did not exercise evidence collection timing.
  now: Bind evidence to fingerprints captured before and after collection, reject changed-candidate results, and test the loader boundary with a controlled mid-run governed-input change.
repair_scope:
  allowed_files:
    - Sources/SkillsBar/Services/DashboardLoader.swift
    - Sources/SkillsBar/Models/DashboardModels.swift
    - Tests/SkillsBarTests/ReviewPopoverTests.swift
    - .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md
  required_outcomes:
    - Capture the governed-input fingerprint before evidence collection starts.
    - Recompute it after collection and accept current receipts only when the fingerprints match.
    - Leave changed-candidate evidence stale or unproven so it contributes zero.
    - Render stage-specific next-action text using actual Swift interpolation.
    - Add regression coverage for a governed input changing during a controlled evidence run and for the first active stage after security passes.
  prohibited:
    - Redesigning the approved pipeline-posture UI or changing its weights.
    - Changing the historical Tessl score boundary.
    - Editing specifications, media, README, assets, release, packaging, or Tessl state.
    - Staging, committing, pushing, or publishing.
fresh_qa_target:
  title: QA-Worker-SkillsBar Pipeline Posture Repair
  artifact: .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-repair-qa.md
  disproof_targets:
    - A governed input changes while evidence commands are running.
    - A later active stage shows literal or generic rather than stage-specific guidance.
    - Existing score arithmetic, gating, icons, and historical Tessl separation regress.
retry_budget:
  repair_worker_followups_remaining: 1
  repair_qa_followups_remaining: 1
claims_boundary: This receipt authorizes a bounded repair and fresh independent QA. It does not accept the implementation or prove live menu-bar, packaging, release, Tessl, commit, or publication state.
```

## Evidence

Command: `sed -n '1,260p' .harness/reports/qa-proofs/2026-07-10-skillsbar-pipeline-posture-qa.md` -> pass (QA proof reports `qa_result: rejected`, HIGH QA-001, and MEDIUM QA-002.)

Command: `git diff --check` -> pass (recorded before repair dispatch; no whitespace diagnostics in the current target-tree diff.)
