# SkillsBar UI contract routing and legacy view cleanup — adversarial review

```yaml
schema: adversarial-review/v1
artifact_id: adversarial-2026-07-19-ui-contract-routing-and-legacy-view-cleanup
task_id: skillsbar-ui-contract-routing-and-legacy-view-cleanup-2026-07-19
role: fresh-adversarial-review
requested_runtime: gpt-5.6-luna/xhigh
runtime_visibility: requested configuration only; observed child runtime unavailable in this delegation surface
observed_at: 2026-07-19T19:41:17Z
head: eb5bd317c9db0642b0990c2d51b939f1030107e1
verdict: rejected
```

## Inputs and preservation boundary

Read the Worker handoff, original rejected QA proof, accepted QA recheck,
steering record, `AGENTS.md`, `README.md`, `SkillContractTests.swift`,
`DashboardView.swift`, `ReleaseEvidenceView.swift`, `Package.swift`, and the
staged-state inventory. This review did not edit, stage, commit, package,
launch, push, or change product source, documentation, tests, or external
state. It writes only this adversarial artifact and the required accountability
artifacts.

The Worker-owned unstaged candidate remains:

- `AGENTS.md`
- `README.md`
- `Tests/SkillsBarTests/SkillContractTests.swift`
- `Sources/SkillsBar/Views/DashboardView.swift`
- `.harness/steering-feedback/2026-07-19-current-ui-contract-routing.json`

The staged `ReleaseEvidenceView.swift` and retained baseline screenshot are
outside the Worker candidate and remain quarantined with the staged `Shell.swift`
and `ShellTests.swift` changes and untracked local skill directory.

## Adversarial results

### P2 — `focusAccent` became dead shared code after the legacy graph deletion

**Finding:** `DashboardView.swift` retains `Color.focusAccent` at line 172,
but the bounded source/test search finds no consumer after the old
`ReviewAction` graph was deleted. The Worker packet required deleting
dependencies that became unreferenced. The accepted QA probe validated a named
list of deleted declarations but did not inspect the retained shared colour
helpers, so it missed this residual dead declaration.

**Exact evidence:**

```text
Sources/SkillsBar/Views/DashboardView.swift:172:    static var focusAccent: Color { Color(red: 0.57, green: 0.63, blue: 0.98) }
```

Command: `zsh -lc 'set -o pipefail; matches=$(rg -n "\\bfocusAccent\\b" Sources Tests); printf "%s\\n" "$matches"; test "$(printf "%s\\n" "$matches" | wc -l | tr -d " ")" -ge 2'` -> fail
(the only match is the declaration, so the required separate consumer is absent).

**Required condition:** remove only `Color.focusAccent`, then rerun the same
consumer probe and the focused `SkillContractTests` command. This is a
source-cleanup condition, not a reason to touch the staged release view or
snapshot evidence.

### P3 — the route guard is maintained, executes, and constrains both documents

**Result:** accepted.

`Package.swift` wires `SkillContractTests` into the maintained `SkillsBarTests`
test target, which depends on the production `SkillsBar` target. The focused
test executed both existing contract tests, including
`testDefaultUIWorkRoutesToApprovedPipelinePostureContract`, with zero failures.
The test asserts the approved and superseded spec metadata, positive current
route/historical-only text in both `AGENTS.md` and README, and rejects the two
known stale default-route sentences. It is deliberately text-contract based;
that is appropriate for the maintained prose route, although it cannot parse
arbitrary future prose rewrites.

Command: `HOME=/private/tmp/skillsbar-contract-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-contract-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-contract-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-contract-test-build --filter SkillContractTests` -> pass
(2 `SkillContractTests` executed with zero failures, including the route guard).

### P4 — no current alternate 2026-07-09 default route was found

**Result:** accepted for the current candidate text.

`AGENTS.md:17` directs UI and behaviour work to the approved 2026-07-10 spec,
approved mockup, active `ReleaseEvidenceView`, and `ReviewPopoverTests`, then
declares the 2026-07-09 material historical and non-default. README describes
the same current route at line 173 and labels the older material
historical/reference-only and non-governing. The bounded route search found no
other default/current/first instruction that directs work to the older spec.

Command: `zsh -lc 'rg -n -i "(start|read|use|default|current|first).{0,100}(2026-07-09|review[- ]popover)|(2026-07-09|review[- ]popover).{0,100}(start|read|use|default|current|first)" AGENTS.md README.md'` -> pass
(all three matches identify the 2026-07-09 material as historical/reference-only; no alternate default route was found).

### P5 — active dependencies survive; staged snapshot mismatch is properly quarantined

**Result:** accepted with a separate blocked visual lane.

`DashboardView` still renders `ReleaseEvidenceView` inside the backdrop and
retains the close control/button style. `TesslLogoLoader` and
`SkillsSDKIconLoader` remain consumed by the active release view; the menu-bar
icon also consumes `SkillsSDKIconLoader`. The named private legacy roots are
absent.

The staged snapshot and staged `ReleaseEvidenceView.swift` are separate
pre-existing state: `git diff --cached --name-status` identifies both paths.
The original QA proof recorded the isolated visual-baseline failure, while this
review did not retry `ReviewPopoverTests` by instruction. The focused contract
test proves compilation through the package target only; it does not prove the
visual snapshot lane.

Command: `zsh -lc 'rg -n "ReleaseEvidenceView\\(|PopoverInteriorBackdrop|PopoverCloseButton|ImmediateFeedbackButtonStyle|TesslLogoLoader|SkillsSDKIconLoader" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Views/ReleaseEvidenceView.swift Sources/SkillsBar/Views/SkillsMenuBarIconView.swift Tests/SkillsBarTests/ReviewPopoverTests.swift'` -> pass
(active root, shell, loader consumers, and focused-render test references remain).

Command: `git diff --cached --name-status -- .harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png Sources/SkillsBar/Views/ReleaseEvidenceView.swift` -> pass
(both mismatched visual-lane paths are staged and outside the Worker candidate).

## Evidence freshness

Candidate paths were observed at `HEAD`
`eb5bd317c9db0642b0990c2d51b939f1030107e1` with these SHA-256 digests:

```text
989fc66870c541052a92eaa7520c59826e8f991e0a4fd13b95b25040ba7e3b5d  AGENTS.md
cf9457e92107efbd867ff769a1c046c922b26a8998bd7fc8f46097c8c66dbf03  README.md
8b79db088a571ddea3221c56de96ce075b902a052d7ade643dabc67c766e8576  Tests/SkillsBarTests/SkillContractTests.swift
6ef0bfec10cc5a7e2430ee685b6f7544e39f159b4d727b6639c0323aa974394b  Sources/SkillsBar/Views/DashboardView.swift
cd7e06508489ff47e0468ce18eb3e11f81ced5f93ba25dbd689efc48b15a6398  .harness/steering-feedback/2026-07-19-current-ui-contract-routing.json
```

## Verdict and claims boundary

**Verdict: rejected.** The documentation-route and maintained-test claims
survive this disproof pass, and the staged visual mismatch remains correctly
quarantined. The candidate does not yet meet its own cleanup boundary because
one newly unreferenced shared helper remains.

After the narrow `focusAccent` removal and focused rerun, require fresh QA and
fresh adversarial review for the amended candidate. Do not treat this result as
proof of `ReviewPopoverTests` visual equivalence, the full suite, live
MenuBarExtra behaviour, installed-bundle state, Tessl/registry authority,
hosted CI/review, signing, notarization, publication, or release readiness.

## Artifact accountability receipt

```yaml
manifest_path: artifacts/agent-runs/default-019f7bac-6205-7ac0-a7ad-14266d8381d5/manifest.json
required_artifact: .harness/reviews/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-adversarial.md
artifact_sha256: recorded in the required run manifest after this review write
```

WROTE: .harness/reviews/2026-07-19-ui-contract-routing-and-legacy-view-cleanup-adversarial.md
