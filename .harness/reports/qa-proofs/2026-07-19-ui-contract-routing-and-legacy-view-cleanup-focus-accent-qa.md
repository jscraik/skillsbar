# SkillsBar current UI routing and legacy cleanup — focused QA after `focusAccent` recovery

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: fresh-independent-qa
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; observed child runtime unavailable in this delegation surface
observed_at: 2026-07-19T19:00:22Z
head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: accepted_focused_recovery
```

## Scope and preservation boundary

This independent QA read the Worker handoff, adversarial review, current
`DashboardView.swift`, and current `SkillContractTests.swift`. It did not edit,
stage, commit, package, launch, push, or change application source,
documentation, the staged release view, or snapshot evidence. The only
project artifact written by this lane is this QA proof; required agent-run
accountability artifacts are recorded separately.

The following paths remain outside this QA candidate and were not exercised:

- staged `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
- staged `Sources/SkillsBar/Views/ReleaseEvidenceView.swift`
- staged `Sources/SkillsBarCore/Shell.swift`
- staged `Tests/SkillsBarCoreTests/ShellTests.swift`
- untracked `.codex/skills/find-animation-opportunities/`
- the pre-existing `ReviewPopoverTests` visual snapshot mismatch.

## Verification

### 1. TDD red/green history is documented

**Result: accepted.** The Worker handoff records both required red/green
sequences:

1. `testDefaultUIWorkRoutesToApprovedPipelinePostureContract` first failed
   against stale AGENTS/README routing, then passed after the documentation
   route changed.
2. `testDashboardViewDoesNotRetainDeletedFocusAccent` first failed while the
   `Color.focusAccent` declaration remained, then passed after only that dead
   declaration was removed.

The handoff's final green command states three `SkillContractTests` executed
with zero failures. The current test source contains both tests and retains the
existing animation-plan contract test, so the focused test target has three
declared test methods.

Evidence source: `.harness/reports/worker-handoffs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-worker.md`, section `Adversarial-review recovery`; `Tests/SkillsBarTests/SkillContractTests.swift:7-64`.

### 2. `Color.focusAccent` has no production declaration or reference

**Result: accepted.** `DashboardView.swift` no longer declares
`Color.focusAccent`, and the production-source search found no `focusAccent`
reference under `Sources`.

Command: `zsh -lc 'if rg -n "\\bfocusAccent\\b" Sources; then exit 11; else print "No production focusAccent dependency remains."; fi'` -> pass (no production reference found).

### 3. Active `DashboardView` dependencies survive the cleanup

**Result: accepted.** The active root still renders
`ReleaseEvidenceView(dashboard:isRefreshing:)` within
`PopoverInteriorBackdrop`, retains the close control and
`ImmediateFeedbackButtonStyle`, and retains both resource loaders. Consumers
remain in the active release view and menu-bar icon path.

Command: `zsh -lc 'rg -n "ReleaseEvidenceView\\(|PopoverInteriorBackdrop|PopoverCloseButton|ImmediateFeedbackButtonStyle|TesslLogoLoader|SkillsSDKIconLoader" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Views/ReleaseEvidenceView.swift Sources/SkillsBar/Views/SkillsMenuBarIconView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift'` -> pass (active root, shell primitives, loader consumers, and focused-render references remain).

### 4. Focused maintained test lane

**Result: accepted.**

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (3 tests executed, 0 failures: pipeline-posture routing, removed `focusAccent`, and animation-plan directory contract).

## Freshness and ownership

The focused checks and file reads occurred at `2026-07-19T19:00:22Z` against
`HEAD eb5bd317c9db0642b0990c2d51b939f1030107e1`.

```text
8c79d3246678ffb6f8a4a6de0e62422e15a4dedb97acdc3250ca63f34d2a810c  Sources/SkillsBar/Views/DashboardView.swift
5a31d926795d9c3640a0e8b58b32d8fcc4eaee5440001736c28d08a985769a84  Tests/SkillsBarTests/SkillContractTests.swift
d04fb2ab78169c22ff4b52d3f794b2900f07663158e0c874c3963000f43a5243  .harness/reports/worker-handoffs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-worker.md
98fb80e371e57a76248a74dd0ebc779fb7e382a92059b886bbdda05a74ceb273  .harness/reviews/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-adversarial.md
```

## Verdict and claims boundary

**Verdict: accepted for the amended, focused `focusAccent` recovery.** The
red/green history is documented, the production `focusAccent` dependency is
absent, the active `DashboardView` dependency boundary remains intact, and the
maintained focused `SkillContractTests` lane passes with three tests.

This proof does **not** establish the blocked `ReviewPopoverTests` visual
snapshot lane, full-suite status, live MenuBarExtra behaviour, installed-bundle
state, Tessl or registry authority, hosted CI/review state, signing,
notarization, publication, or release readiness. It does not reclassify the
staged `ReleaseEvidenceView.swift` or retained snapshot baseline.

## Artifact accountability receipt

```yaml
manifest_path: artifacts/agent-runs/default-019f7bbd-10a4-7811-a222-44c178c64eaf/manifest.json
required_artifact: .harness/reports/qa-proofs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent-qa.md
```

WROTE: .harness/reports/qa-proofs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-focus-accent-qa.md
