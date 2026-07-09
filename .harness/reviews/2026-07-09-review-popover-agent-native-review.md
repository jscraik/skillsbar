# Agent-Native Review: Review Popover Refactor Spec

schema_version: 1
reviewer: agent-native-reviewer
target_repo: /Users/jamiecraik/dev/skillsbar
target_spec: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
review_date: 2026-07-09
scope: MenuBarExtra popover refactor handoff for the final-polish Skills SDK mockup

## Bottom Line

The spec is a useful visual and behavior contract for the MenuBarExtra popover, but it is not yet agent-native enough for a low-context implementation agent to refactor the current SwiftUI surface without making product decisions. The main blockers are command canonicality, deterministic state setup for the final mockup, and concrete UI validation commands. The repo already has strong proof-boundary language, a snapshot renderer, build/test/launch wrappers, persisted media, and clear AGENTS guidance; the next move is to convert those into mechanical implementation fixtures and explicit command contracts.

## Working Strengths

- dimension: context_routing
  finding: Repo instructions route implementation agents to the exact spec before UI or behavior work.
  evidence: AGENTS.md says UI/behavior work should check `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md`.

- dimension: proof_of_work
  finding: The spec separates generated mockup evidence from live MenuBarExtra proof and lists clipboard, focus, reduced-motion, and height as runtime gates.
  evidence: `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md` contains `proof_boundary`, `non_proof_sources`, and validation gates V-004 through V-008.

- dimension: durable_repo_knowledge
  finding: The final-polish mockup and prompt sidecar are persisted in repo-owned harness media instead of relying only on chat context.
  evidence: `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png` and `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.prompt.md` exist.

- dimension: autonomous_execution_loop
  finding: The current app has a scriptable SwiftUI snapshot path that can become a visual regression/proof hook for the MenuBarExtra popover content.
  evidence: `Sources/SkillsBar/Support/Snapshot.swift` supports `--snapshot <path>`; `Sources/SkillsBar/App/SkillsBarApp.swift` exits after rendering a snapshot.

- dimension: proof_of_work
  finding: Repo-native build and test commands are documented and currently pass.
  evidence: Commands listed in the Validation Evidence section.

## Gaps

### G-001 High: Canonical copy command is still unresolved even though the implementation has two plausible commands

- dimension: capability_parity_and_tool_design
- failure_category: claim_boundary
- finding: The spec says the canonical command is unresolved and blocks implementation, while the current app exposes both `dashboard.security.inspectCommand` and `dashboard.selectedSkillInspectCommand`. The mockup/action copy says `Copy inspect command` and `Inspect 1 critical, 2 high in SKILL.md`, but current `CommandDock` copies the security risk-modes command when security is flagged and only exposes the SKILL.md inspect command as the secondary command.
- evidence: `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md` FR-008 through FR-010; `Sources/SkillsBar/Views/DashboardView.swift` `CommandDock.actionCommand`, `CommandDock.secondaryCommand`, and the flagged-state button action; `Sources/SkillsBar/Models/DashboardModels.swift` `selectedSkillInspectCommand`.
- next_move: Before implementation, decide one canonical action model: either copy the risk-modes evidence command, copy a SKILL.md inspection command, or expose both with distinct labels. Then update FR-008, FR-009, FR-010, SA-007, and the Swift model name to match.

### G-002 High: No deterministic final-mockup state fixture exists for local quality/impact/security

- dimension: mechanical_guardrails
- failure_category: missing_validation
- finding: README documents Tessl registry fixture variables, but there is no equivalent fixture for local package quality, 71/71 impact, or 3 security risks. The current loader runs live `./bin/ask` commands against `/Users/jamiecraik/dev/agent-skills`, so an implementation agent cannot reliably render the exact SA-001 through SA-006 state for screenshot comparison.
- evidence: README fixture section mentions only `TESSL_REGISTRY_FIXTURE*`; `DashboardLoader.load()` runs package, scenario, and security commands live; `SnapshotRenderer.render` depends on `DashboardLoader().loadSync()`.
- next_move: Add a local dashboard fixture mode, for example `SKILLSBAR_DASHBOARD_FIXTURE=review_popover_final_polish`, that returns the exact spec values: score 78, quality 100%, impact 71/71, security 3 risks with 1 critical and 2 high, registry score 66, registry impact 63%, security Passed, and 68 registry evals. Use it for snapshot and UI tests.

### G-003 Medium: The spec does not map acceptance IDs to current SwiftUI components

- dimension: context_routing
- failure_category: context_routing
- finding: The implementation surface is discoverable, but the spec does not tell an implementation agent which current components are obsolete, reusable, or intended to become the final-polish sections. The existing UI has `ProofLaneComparisonView`, `FleetSummaryView`, `LocalChecksPanel`, `SecurityBlock`, and `CommandDock`, while the spec calls for a different composition: header, package identity, local review trigger card, secondary registry row, bridge row, and neutral action card.
- evidence: `Sources/SkillsBar/Views/DashboardView.swift` current body includes comparison/fleet/local/security/action sections; spec requirements FR-001 through FR-013 describe a different popover hierarchy.
- next_move: Add an implementation mapping table to the spec: acceptance ID, current component(s), target component(s), keep/refactor/delete decision, and source model fields.

### G-004 Medium: Visual validation is described but not executable

- dimension: proof_of_work
- failure_category: proof_gap
- finding: The spec requires screenshot comparison against the persisted mockup, but it does not provide a concrete command that renders a deterministic snapshot or names where to save the actual output. The app already has `--snapshot`, so this is a small guardrail gap rather than a missing capability.
- evidence: Validation gate V-004 says runtime screenshot compared with persisted mockup; `SnapshotRequest` and `SnapshotRenderer` exist but are not referenced by the spec or README validation section.
- next_move: After adding fixture mode, document and use a command like `SKILLSBAR_DASHBOARD_FIXTURE=review_popover_final_polish swift run SkillsBar --snapshot .harness/reviews/2026-07-09-review-popover-actual.png`, followed by a screenshot compare or manual attached evidence path.

### G-005 Medium: Accessibility and focus requirements lack a repo-native proof route

- dimension: proof_of_work
- failure_category: missing_validation
- finding: The spec correctly requires accessible names and focus traversal, and `CopyIconButton` has accessibility labels. However, there is no UI test, accessibility inspection script, or documented manual protocol for the MenuBarExtra popover. Current tests cover only shell output handling.
- evidence: `CopyIconButton.accessibilityLabel(help)`; `Tests/SkillsBarCoreTests/ShellTests.swift` contains only `testRunCapturesLargeStdoutAndStderrWithoutDeadlock`; V-006 is blocked until implementation/run exists.
- next_move: Add either a minimal XCTest/UI inspection harness for the snapshot view or a manual proof checklist requiring screenshot/focus path evidence with exact controls: menu bar item, details button, copy button, command field.

### G-006 Low: README still points project-layout readers at the older final mockup only

- dimension: durable_repo_knowledge
- failure_category: context_routing
- finding: README lists `.harness/media/2026-07-09-skills-sdk-menubar-final-mockup.png` but not the final-polish media or prompt sidecar. A fresh agent reading README before the spec can miss that the old mockup is superseded.
- evidence: README Project Layout table lists only the earlier final mockup; the spec says final-polish supersedes prior mockup when visuals disagree.
- next_move: Update README Project Layout or Development Notes to name the final-polish mockup and prompt sidecar as the current visual target.

## Validation Recommendations

- structural/build lane: keep running the documented SwiftPM build after code changes.
- unit lane: keep `swift test`, but do not treat current tests as UI proof.
- launch lane: use `NO_OPEN=1 ./Launch.command` for bundle construction, then `script/build_and_run.sh --verify` only when live MenuBarExtra launch is appropriate.
- snapshot lane: add deterministic final-polish fixture mode and snapshot command before closing visual acceptance.
- runtime lane: after implementation, provide fresh evidence for screenshot, clipboard full-command copy, keyboard focus, reduced motion, reduced transparency/contrast if supported, and height fit.

## Validation Evidence

- Command: `test -f .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png` -> pass (exit 0)
- Command: `test -f .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.prompt.md` -> pass (exit 0)
- Command: `HOME=/private/tmp/skillsbar-agent-review-home XDG_CACHE_HOME=/private/tmp/skillsbar-agent-review-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-agent-review-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-agent-review-build` -> pass (exit 0)
- Command: `HOME=/private/tmp/skillsbar-agent-review-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-agent-review-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-agent-review-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-agent-review-test-build` -> pass (exit 0; current tests cover Shell only, not UI)
- Command: `SKILLSBAR_BUILD_ROOT=/private/tmp/skillsbar-agent-review-launch NO_OPEN=1 ./Launch.command` -> blocked (tool wrapper did not return a reliable exit code before output ended; nearest evidence `test -x /private/tmp/skillsbar-agent-review-launch/SkillsBar.app/Contents/MacOS/SkillsBar` passed)
- Command: `test -x /private/tmp/skillsbar-agent-review-launch/SkillsBar.app/Contents/MacOS/SkillsBar` -> pass (exit 0; proves bundle executable exists, not live popover behavior)
- Command: `pgrep -fl "swift build|Launch.command|SkillsBar" || true` -> blocked (sandbox process-list access failed with `sysmon request failed with error: sysmond service not found` and `pgrep: Cannot get process list`)

## Residual Risk

- This is a read-only review plus artifact write. It does not implement the final-polish popover.
- No live MenuBarExtra popover was opened or inspected.
- No clipboard, focus traversal, reduced-motion, or accessibility tree validation was performed.
- No snapshot comparison was performed because deterministic final-polish fixture data does not yet exist.
- Tessl and local Skills SDK live command truth were not refreshed beyond reading current source contracts.

## Agent-Native Score

score: 72

Rationale: The repo has strong guidance, proof boundaries, persisted media, and native build/test paths. It loses points because a low-context implementation agent still has to decide the copied command semantics, invent a deterministic fixture strategy, infer component mapping, and create executable visual/accessibility proof routes.
