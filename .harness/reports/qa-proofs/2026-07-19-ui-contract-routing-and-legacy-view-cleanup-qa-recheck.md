# SkillsBar UI contract routing and legacy view cleanup — QA recheck

```yaml
schema: qa-proof/v1
artifact_id: qa-recheck-2026-07-19-ui-contract-routing-and-legacy-view-cleanup
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: fresh-independent-qa-disproof-recheck
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; observed child runtime is unavailable in this delegation surface
observed_at: 2026-07-19T18:35:42Z
head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: accepted
```

## Inputs, scope, and ownership

Read the Worker handoff, the rejected QA proof, the current steering record,
`AGENTS.md`, `README.md`, `SkillContractTests.swift`, and `DashboardView.swift`.
This lane did not edit, stage, commit, package, launch, push, or change product
source, documentation, tests, or external state. It writes only this proof and
the required agent run manifest.

The rechecked Worker-owned candidate is the unstaged route/docs/test/view slice:

- `AGENTS.md`
- `README.md`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `.harness/steering-feedback/2026-07-19-current-ui-contract-routing.json`

Preserved outside this QA scope: staged
`.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`,
`Sources/SkillsBar/Views/ReleaseEvidenceView.swift`,
`Sources/SkillsBarCore/Shell.swift`, and
`Tests/SkillsBarCoreTests/ShellTests.swift`; the untracked
`.codex/skills/find-animation-opportunities/`; and existing Worker/QA artifacts.

## Recheck verdicts

### Current default route and historical-only boundary — accepted

The recovered test now proves both required directions:

1. **Positive route regression:** it fails if the approved 2026-07-10
   pipeline-posture specification, its approved mockup, or the active
   `ReleaseEvidenceView` route is removed from either maintained guidance
   surface.
2. **Negative route regression:** it fails if `AGENTS.md` stops calling the
   2026-07-09 materials historical and non-default, if `README.md` stops
   calling them historical/reference-only and non-governing, or if either
   superseded default-route sentence returns.

This is not inferred from a summary: `SkillContractTests` contains positive
`XCTAssertTrue` assertions for both maintained-document current-route claims
and historical-only claims, alongside `XCTAssertFalse` assertions for the two
known stale routes. The current source text satisfies every assertion.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (2 `SkillContractTests` executed with zero failures; includes `testDefaultUIWorkRoutesToApprovedPipelinePostureContract`).

Command: `zsh -lc 'set -o pipefail; rg -n -C 1 "historical reference only|default implementation contract|historical/reference-only|do not govern new pipeline-posture changes|2026-07-10-skillsbar-pipeline-posture-spec" Tests/SkillsBarTests/SkillContractTests.swift AGENTS.md README.md; if rg -n "^private (struct|extension) (PipelinePostureHeader|PipelineReadinessSummary|WeightedReadinessBar|PipelineStageCard|PipelineConnector|PipelineStageRow|TesslRegistryCard|HistoricalMetricColumn|PipelineAction|ReviewHeader|ScoreHex|PackageIdentity|RefreshStatus|ReviewTriggerCard|MetricColumn|RegistryEvidenceRow|RegistryVisibilityBadge|RegistryMetric|EvidenceBridge|ReviewAction|ScaledSystemFontModifier|CopyConfirmationMotion|SkillsSDKLogoView|TesslLogoView|QuietDivider|VerticalDivider|RoundedHexagon)" Sources/SkillsBar/Views/DashboardView.swift; then exit 1; else print "PASS: no deleted private legacy declaration remains in DashboardView.swift."; fi; rg -n "ReleaseEvidenceView\\(|PopoverInteriorBackdrop|PopoverCloseButton|ImmediateFeedbackButtonStyle|SkillsSDKIconLoader|TesslLogoLoader" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Views/ReleaseEvidenceView.swift Sources/SkillsBar/Views/SkillsMenuBarIconView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift; git rev-parse HEAD; shasum -a 256 AGENTS.md README.md Tests/SkillsBarTests/SkillContractTests.swift Sources/SkillsBar/Views/DashboardView.swift .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json'` -> pass (all current/historical guard strings present; no deleted private legacy declarations; active root/backdrop/close/button style/loaders and external loader consumers remain; candidate SHA-256 values recorded below).

### Legacy private view graph and active shell — accepted

`DashboardView` remains a single active root rendering
`ReleaseEvidenceView(dashboard:isRefreshing:)`. The retained active shell is
present: `PopoverInteriorBackdrop`, `PopoverCloseButton`, and
`ImmediateFeedbackButtonStyle`. `SkillsSDKIconLoader` remains consumed by the
menu-bar icon and active release view; `TesslLogoLoader` remains consumed by
the active release view. The targeted source probe found none of the named
removed private legacy declarations.

The relevant types were private, so an unresolved retained caller would fail
the focused Swift build performed by `SkillContractTests`. This recheck does
not claim visual equivalence or the separately quarantined snapshot lane.

### Steering record — accepted

Command: `git diff --check && python3 /Users/jamiecraik/dev/configs/codex/scripts/validate-steering-feedback.py --input .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json --json` -> pass (`git diff --check` emitted no diagnostics; steering validator returned `status: pass` with no errors).

## Candidate digests

```text
989fc66870c541052a92eaa7520c59826e8f991e0a4fd13b95b25040ba7e3b5d  AGENTS.md
cf9457e92107efbd867ff769a1c046c922b26a8998bd7fc8f46097c8c66dbf03  README.md
8b79db088a571ddea3221c56de96ce075b902a052d7ade643dabc67c766e8576  Tests/SkillsBarTests/SkillContractTests.swift
6ef0bfec10cc5a7e2430ee685b6f7544e39f159b4d727b6639c0323aa974394b  Sources/SkillsBar/Views/DashboardView.swift
cd7e06508489ff47e0468ce18eb3e11f81ced5f93ba25dbd689efc48b15a6398  .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json
```

## Freshness and claims boundary

Fresh for `HEAD` `eb5bd317c9db0642b0990c2d51b939f1030107e1` and the candidate
file digests above at `2026-07-19T18:35:42Z`. The QA result accepts the
document-routing regression guard, its historical/non-default disproof branch,
private legacy-root deletion, retained active shell/loaders, source compilation
through the focused test build, whitespace check, and validated steering record.

It does **not** accept or prove the separately quarantined `ReviewPopoverTests`
visual snapshot lane, full-suite status, live MenuBarExtra behaviour,
installed-bundle state, Tessl or registry authority, hosted CI/review, signing,
notarization, publication, or release readiness. `ReviewPopoverTests` was not
run in this recheck by explicit task instruction because the remaining mismatch
belongs to staged visual source/evidence outside the Worker slice.

## Artifact accountability receipt

```yaml
manifest_path: artifacts/agent-runs/default-019f7ba6-8f21-7661-bccf-a10a224af785/manifest.json
required_artifact: .harness/reports/qa-proofs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-qa-recheck.md
artifact_sha256: recorded in the required run manifest after this proof write
```

WROTE: .harness/reports/qa-proofs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-qa-recheck.md
