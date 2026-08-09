---
schema_version: pm-child-task-packet/v1
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
project: SkillsBar
role: Worker
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; this delegation surface does not expose a Luna selector or observed child runtime attestation
base_head: eb5bd31
authority: user-approved implementation of the 2026-07-19 directory-backtest recommendations
---

# Worker packet — current UI routing and legacy view cleanup

## Objective

Make the default UI-work route deterministic and remove the inactive private
legacy view graph only after re-verifying its caller boundary.

## Allowed canonical files

- `AGENTS.md`
- `README.md`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `.harness/steering-feedback/2026-07-19-current-ui-contract-routing.json`
- `.harness/reports/worker-handoffs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-worker.md`

## Preserve without modification

- the pre-existing staged changes in `ReleaseEvidenceView.swift`, `Shell.swift`,
  `ShellTests.swift`, and `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- the untracked `.codex/skills/find-animation-opportunities/` directory
- all build outputs, app bundles, registry, hosted, package, signing, and release state

## Required TDD sequence

1. Reconfirm the active caller path: `DashboardView` -> `ReleaseEvidenceView`.
2. Add focused `SkillContractTests` coverage for both sides of the routing
   invariant: the 2026-07-10 pipeline-posture spec is approved/current and the
   2026-07-09 review-popover spec is superseded/historical. Run that test
   before changing the docs and record the expected red result.
3. Update `AGENTS.md` and `README.md` to route current UI work to the approved
   pipeline-posture spec, its approved mockup, active `ReleaseEvidenceView`,
   and focused tests. Retain the older review-popover spec/materials as
   historical/reference-only.
4. Reconfirm the private legacy graph has no caller outside itself. Remove only
   the unreferenced graph and any dependencies that become unreferenced. Keep
   the live backdrop, close button, icon loaders, color/font helpers, and any
   component used by the active release view or app entrypoint.
5. Update the steering record to `implemented` only after its focused proof
   passes, replacing the skipped proof row with exact command evidence.
6. Write the worker handoff report named above. Include changed paths, red and
   green test results, caller/reference evidence, preservation boundary,
   validation commands, residual risks, and claims boundary. End exactly with:
   `WROTE: .harness/reports/worker-handoffs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-worker.md`

## Validation

Use the repository’s isolated SwiftPM command. Start focused, then widen only
after it passes:

```bash
HOME=/private/tmp/skillsbar-contract-test-home \
XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg \
CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
swift test --build-system native --disable-sandbox \
  --build-path /private/tmp/skillsbar-contract-test-build \
  --filter SkillContractTests
```

Then run the affected `ReviewPopoverTests` and the full canonical suite only
after the focused lane passes. Also run `git diff --check`.

## Stop conditions

- Any alleged legacy dependency has an external caller or an unclear retention
  purpose.
- A focused test failure is not explained by the new invariant.
- A test/runtime failure is caused by pre-existing staged state, sandbox,
  toolchain, or cache authority rather than the patch.
- The unavailable `validation-contract-check` skill is necessary for a safe
  action beyond the focused repository contract test.

## Claims boundary

This task may prove source routing, source deletion, and local Swift test
lanes. It cannot prove live MenuBarExtra behavior, installed-bundle state,
Tessl/registry authority, hosted checks, review status, signing, notarization,
or release readiness.
