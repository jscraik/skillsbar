# SkillsBar UI contract routing and legacy view cleanup — QA disproof

```yaml
schema: qa-proof/v1
artifact_id: qa-2026-07-19-ui-contract-routing-and-legacy-view-cleanup
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: fresh-independent-qa-disproof
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; observed child runtime is unavailable in this delegation surface
observed_at: 2026-07-19T18:27:27Z
head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: rejected_incomplete_regression_guard
```

## Scope and dirty ownership

This QA lane made no source, documentation, test, staging, package, launch,
commit, push, or external-state changes. It created only this required QA proof
and the mandated agent accountability artifacts.

The Worker-owned, unstaged candidate paths are `AGENTS.md`, `README.md`,
`Sources/SkillsBar/Views/DashboardView.swift`, and
`Tests/SkillsBarTests/SkillContractTests.swift`, plus its handoff and steering
records. Preserved non-Worker state includes staged
`.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`,
`Sources/SkillsBar/Views/ReleaseEvidenceView.swift`,
`Sources/SkillsBarCore/Shell.swift`, and `Tests/SkillsBarCoreTests/ShellTests.swift`,
and untracked `.codex/skills/find-animation-opportunities/`.

## Independent claim disproof

### Claim 1 — current default UI route

**Verdict: accepted.** `AGENTS.md` directs UI and behaviour work first to the
2026-07-10 pipeline-posture spec, approved mockup, active `ReleaseEvidenceView`,
and `ReviewPopoverTests`. It labels the 2026-07-09 review-popover materials
historical/reference-only and non-default. README documents the same active route
and marks the earlier material historical in both the layout table and development
notes.

Command: `zsh -lc 'rg -n -C 2 "2026-07-10|2026-07-09|ReleaseEvidenceView|historical|current UI work" AGENTS.md README.md'` -> pass (both maintained instruction surfaces explicitly route to the 2026-07-10 contract and mark 2026-07-09 material historical.)

### Claim 2 — private legacy graph removal and retained active dependencies

**Verdict: accepted.** The active `DashboardView` content root remains
`ReleaseEvidenceView(dashboard:isRefreshing:)`; the backdrop, close button,
its button style, and the shared Skills SDK/Tessl loaders remain. The active
release view and the menu-bar icon retain loader consumers. No declaration of
the named deleted private legacy graph remains. Since the removed types were
private, a remaining external caller would be a compiler failure; the focused
Swift test build successfully compiled the maintained target.

Command: `zsh -lc 'if rg -n "^private (struct|extension) (PipelinePostureHeader|PipelineReadinessSummary|WeightedReadinessBar|PipelineStageCard|PipelineConnector|PipelineStageRow|TesslRegistryCard|HistoricalMetricColumn|PipelineAction|ReviewHeader|ScoreHex|PackageIdentity|RefreshStatus|ReviewTriggerCard|MetricColumn|RegistryEvidenceRow|RegistryVisibilityBadge|RegistryMetric|EvidenceBridge|ReviewAction|ScaledSystemFontModifier|CopyConfirmationMotion|SkillsSDKLogoView|TesslLogoView|QuietDivider|VerticalDivider|RoundedHexagon)" Sources/SkillsBar/Views/DashboardView.swift; then exit 1; else print "No removed private legacy declaration remains in DashboardView.swift."; fi'` -> pass (no deleted private declaration remains.)

Command: `zsh -lc 'rg -n "ReleaseEvidenceView\\(|PopoverInteriorBackdrop|PopoverCloseButton|ImmediateFeedbackButtonStyle|SkillsSDKIconLoader|TesslLogoLoader" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Views/ReleaseEvidenceView.swift Sources/SkillsBar/Views/SkillsMenuBarIconView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift'` -> pass (active release root, close control, backdrop, loader consumers, and focused test references remain.)

### Claim 3 — focused contract test is a complete routing regression guard

**Verdict: rejected.** The new test is a real but partial guard: it proves the
approved specification and mockup are present and that AGENTS/README mention the
new route. It does **not** assert that either maintained document labels the
2026-07-09 material historical/reference-only, nor that it is prohibited as the
default route. A future edit could reintroduce the old spec as a current/default
route while preserving every current `XCTAssertTrue` assertion.

The smallest repair is to add explicit negative/positive assertions for the
historical-only boundary in both AGENTS and README, or a narrow parsed route
contract if prose wording must remain flexible. Rerun this exact focused command
after that repair before retrying QA.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass (2 tests executed with zero failures; proves the current, incomplete assertions execute against the maintained package.)

## Additional focused lane

`ReviewPopoverTests` was safe to run after the focused test. It failed one visual
baseline comparison: 53 executed, 52 passed, and
`testReviewFixtureRenderMatchesRetainedBaseline` observed
`0.02619804474319981` above its `0.0005` threshold. The failure exercises the
active `ReleaseEvidenceView` path and the retained screenshot. Both
`ReleaseEvidenceView.swift` and
`.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`
are visible staged, non-Worker state. Nothing in the `DashboardView` deletion or
the route/docs test ties the changed pixel output to the Worker patch.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter ReviewPopoverTests` -> fail (unrelated dirty-worktree/pre-existing snapshot mismatch; 52 of 53 focused tests passed and the only failure is the retained-baseline pixel comparison.)

Command: `git diff --check` -> pass (no whitespace diagnostics in the visible diff.)

## Required next action

The Worker must make one bounded test-only follow-up: extend
`testDefaultUIWorkRoutesToApprovedPipelinePostureContract` to fail if AGENTS or
README stops saying the 2026-07-09 spec/material is historical/reference-only
and non-default. Then rerun the exact `SkillContractTests` command above and
request fresh QA. Do not retry the same visual snapshot lane until its separate
staged source/evidence owner reconciles `ReleaseEvidenceView.swift` with the
retained baseline.

## Freshness and claims boundary

This proof is fresh for the observed `eb5bd317c9db0642b0990c2d51b939f1030107e1`
checkout and the dirty ownership inventory at 2026-07-19T18:27:27Z. It proves
the current text routing, active/deleted source shape, and focused test outcomes.
It does not prove the requested full regression guard, full visual baseline,
full suite, live MenuBarExtra behaviour, installed bundle, registry/Tessl,
hosted CI/review, signing, notarization, publication, or release readiness.

WROTE: .harness/reports/qa-proofs/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-qa.md
