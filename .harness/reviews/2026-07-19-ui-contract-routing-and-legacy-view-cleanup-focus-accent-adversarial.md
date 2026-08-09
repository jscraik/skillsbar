# SkillsBar UI contract routing and legacy cleanup — final focus-accent adversarial review

```yaml
schema: adversarial-review/v1
artifact_id: adversarial-2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: fresh-adversarial-review
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; observed child runtime unavailable in this delegation surface
observed_at: 2026-07-19T19:08:57Z
head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: rejected_scoped_residual_legacy_model
```

## Inputs and preservation boundary

Read the Worker packet and recovery handoff, the original QA proof, QA recheck,
focus-accent QA proof, original adversarial review, the steering record,
current `AGENTS.md`, README, `DashboardView.swift`, `SkillContractTests.swift`,
and relevant source/test callers. This review did not edit, stage, commit,
package, launch, push, or alter source, docs, tests, app, registry, hosted, or
release state. It writes only this required review and accountability artifacts.

The Worker-owned unstaged candidate remains `AGENTS.md`, `README.md`,
`Sources/SkillsBar/Views/DashboardView.swift`,
`Tests/SkillsBarTests/SkillContractTests.swift`, and the steering record.
Staged `ReleaseEvidenceView.swift`, `Shell.swift`, `ShellTests.swift`, and the
retained snapshot evidence remain outside this candidate, as does the
untracked `find-animation-opportunities` skill directory.

## Severity-ranked results

### P2 — residual production legacy model remains after removal of its only production view graph

**Finding: rejected.** `ReviewPresentation` remains as a production-model
declaration, yet its only references are nine legacy assertions in
`ReviewPopoverTests`; no production source constructs or consumes it. The
Worker packet required removing dependencies that became unreferenced after the
private legacy graph deletion. This is not a defect in the active shell, but it
means the cleanup claim is incomplete and leaves inactive review-popover
semantics and tests in the maintained source tree.

**Ownership:** `introduced_by_current_patch` at the contract level: deletion of
the sole production consumers left this pre-existing model without a production
caller. The resolution requires a newly scoped change to
`Sources/SkillsBar/Models/DashboardModels.swift` and the obsolete
`ReviewPresentation` tests in `Tests/SkillsBarTests/ReviewPopoverTests.swift`;
both files were outside the Worker packet, so this reviewer did not edit them.

**Exact evidence:**

```text
Sources/SkillsBar/Models/DashboardModels.swift:830:struct ReviewPresentation {
Tests/SkillsBarTests/ReviewPopoverTests.swift:56,68,90,103,162,177,189,208,220
```

Command: `zsh -lc 'matches=$(rg -n "\\bReviewPresentation\\b" Sources/SkillsBar); printf "%s\n" "$matches"; test "$(printf "%s\n" "$matches" | wc -l | tr -d " ")" -eq 1'` -> pass (the only production source match is the declaration at `DashboardModels.swift:830`; the source has no production caller).

**Required recovery:** create a new, explicitly scoped TDD slice. First add a
characterization/removal test or source-reference assertion for the model and
its legacy-only tests; then remove `ReviewPresentation` and its obsolete tests
only after confirming no active public/package consumer exists. Do not touch
the quarantined visual snapshot paths to resolve this finding. Require a fresh
QA disproof and fresh adversarial review for that amended scope.

### P3 — `focusAccent` recovery is correct; the static guard is intentionally file-scoped

**Result: accepted with a boundary caveat.** There are currently zero
production `focusAccent` references. The maintained static test scans
`DashboardView.swift`, which is the canonical file from which the deleted
legacy dependency originated. It meaningfully prevents reintroducing that
deleted Dashboard dependency; it is not and should not be represented as a
global prohibition on a future, independently justified colour token.

Command: `zsh -lc 'if rg -n "\\bfocusAccent\\b" Sources; then exit 12; else print "No production focusAccent refs remain."; fi'` -> pass (no match under `Sources`).

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> blocked (the final adversarial invocation was interrupted after a prolonged runtime stall; do not infer a fresh result from the interruption and do not rerun this lane in this review).

The earlier focus-accent QA proof is a separate historical lane: it records a
passing three-test execution at `2026-07-19T19:00:22Z`, before this final
review. It supports the previous recovery evidence but is not fresh validation
owned by this adversarial pass.

### P3 — current documentation and contract test protect both the positive and negative UI route

**Result: accepted.** `AGENTS.md` begins UI/behaviour work with the approved
2026-07-10 pipeline-posture spec, approved mockup, active
`ReleaseEvidenceView`, and focused `ReviewPopoverTests`; it marks the 2026-07-09
material historical and non-default. README repeats the route and calls the old
materials historical/reference-only and non-governing. The contract test checks
both specification metadata, both maintained documents, and the removed stale
route sentences.

Command: `zsh -lc 'rg -n -i "(start|read|use|default|current|first).{0,140}(2026-07-09|review[- ]popover)|(2026-07-09|review[- ]popover).{0,140}(start|read|use|default|current|first)" AGENTS.md README.md'` -> pass (all current instruction-document matches label the 2026-07-09 material historical/reference-only; no maintained alternate default route found).

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> blocked (same interrupted final-adversarial runtime lane; historical QA remains separate and is not promoted to a fresh review result).

### P3 — active dashboard root, close shell, and loaders remain; named private view roots are absent

**Result: accepted.** `DashboardView` continues to render
`ReleaseEvidenceView(dashboard:isRefreshing:)` inside `PopoverInteriorBackdrop`,
with `PopoverCloseButton` and `ImmediateFeedbackButtonStyle`. `SkillsSDKIconLoader`
and `TesslLogoLoader` remain consumed by the active release and menu-bar paths.
The named deleted private legacy declarations are absent from `DashboardView`.

Command: `zsh -lc 'rg -n "ReleaseEvidenceView\\(|PopoverInteriorBackdrop|PopoverCloseButton|ImmediateFeedbackButtonStyle|TesslLogoLoader|SkillsSDKIconLoader" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Views/ReleaseEvidenceView.swift Sources/SkillsBar/Views/SkillsMenuBarIconView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift'` -> pass (active root, shell primitives, loader consumers, and focused-render reference remain).

Command: `zsh -lc 'if rg -n "^private (struct|extension) (PipelinePostureHeader|PipelineReadinessSummary|WeightedReadinessBar|PipelineStageCard|PipelineConnector|PipelineStageRow|TesslRegistryCard|HistoricalMetricColumn|PipelineAction|ReviewHeader|ScoreHex|PackageIdentity|RefreshStatus|ReviewTriggerCard|MetricColumn|RegistryEvidenceRow|RegistryVisibilityBadge|RegistryMetric|EvidenceBridge|ReviewAction|ScaledSystemFontModifier|CopyConfirmationMotion|SkillsSDKLogoView|TesslLogoView|QuietDivider|VerticalDivider|RoundedHexagon)" Sources/SkillsBar/Views/DashboardView.swift; then exit 13; else print "No named legacy private roots remain."; fi'` -> pass (none remain).

### P3 — no accidental change to staged visual/runtime lane observed

**Result: accepted for ownership, not visual equivalence.** The four changed
candidate paths are unstaged; the separate staged visual and shell paths remain
outside the Worker candidate. `git diff --check` has no whitespace diagnostics.

Command: `git diff --name-status` -> pass (only `AGENTS.md`, README, `DashboardView.swift`, and `SkillContractTests.swift` are unstaged Worker candidate files).

Command: `git diff --cached --name-status` -> pass (the staged release view,
snapshot, shell, and shell-test paths remain distinct from this candidate).

Command: `git diff --check` -> pass (no whitespace diagnostics).

## Freshness and candidate identity

Observed at `2026-07-19T19:08:57Z` on `HEAD`
`eb5bd317c9db0642b0990c2d51b939f1030107e1`.

```text
989fc66870c541052a92eaa7520c59826e8f991e0a4fd13b95b25040ba7e3b5d  AGENTS.md
cf9457e92107efbd867ff769a1c046c922b26a8998bd7fc8f46097c8c66dbf03  README.md
8c79d3246678ffb6f8a4a6de0e62422e15a4dedb97acdc3250ca63f34d2a810c  Sources/SkillsBar/Views/DashboardView.swift
5a31d926795d9c3640a0e8b58b32d8fcc4eaee5440001736c28d08a985769a84  Tests/SkillsBarTests/SkillContractTests.swift
cd7e06508489ff47e0468ce18eb3e11f81ced5f93ba25dbd689efc48b15a6398  .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json
```

## Verdict and claims boundary

**Verdict: rejected for the full cleanup claim, accepted for the amended
focus-accent, route-currentness, and active-shell subclaims.** The candidate
does not yet establish that all now-unreferenced legacy production surfaces were
removed because `ReviewPresentation` and its legacy-only tests remain.

This review proves only bounded source/text searches, documentation-route text,
candidate ownership, and whitespace checking. The fresh focused SwiftPM lane is
**blocked** by an interrupted prolonged runtime attempt; the earlier accepted
QA test result remains historical evidence only. This review does **not** prove
the blocked `ReviewPopoverTests` visual snapshot lane, full suite, live
MenuBarExtra behaviour, installed bundle, Tessl/registry truth, hosted
CI/review, signing, notarization, publication, or release readiness.

## Artifact accountability receipt

```yaml
manifest_path: artifacts/agent-runs/default-019f7bc2-37b1-7d70-84be-ccecc8d4e695/manifest.json
required_artifact: .harness/reviews/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent-adversarial.md
artifact_sha256: pending_manifest_write
```

WROTE: .harness/reviews/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent-adversarial.md
