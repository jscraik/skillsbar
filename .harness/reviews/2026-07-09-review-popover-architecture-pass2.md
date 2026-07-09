# Architecture Pass 2: Review Popover Spec Handoff

schema_version: 1
date: 2026-07-09
reviewer: architecture-strategist-pass2
target: SkillsBar macOS MenuBarExtra(.window) review popover
spec_path: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
synthesis_path: .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md
implementation_scope: current SwiftUI shell and popover refactor route

## Bottom Line

The first three-lane findings were implemented into the spec at the architecture-boundary level: the spec now preserves MenuBarExtra(.window), names the final-polish mockup as the visual target, requires a copy-only review action, requires a deterministic final-polish fixture, and separates generated-image proof from live runtime proof. I do not see a remaining reason to change the app shell or introduce a normal macOS app-window architecture. I do see three remaining handoff conflicts that can still cause divergent implementations unless the spec or implementation plan tightens them before code closeout.

## Fold-In Verification

- Menu-bar shell boundary is present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:110 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:159.
- Copy-only review action is present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:143 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:329.
- Deterministic final-polish fixture requirement is present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:144 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:330.
- Final-polish mockup supersedes earlier visual direction: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:120-124 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:337-347.
- README routes future agents to the final-polish mockup: README.md:102-104.

## Remaining Findings

### P1. Fixture boundary is named, but not architecturally precise enough for implementation

The spec requires a deterministic final-polish fixture, and the synthesis proposes an environment-driven snapshot command. The current implementation only has Tessl registry fixture support, while local review state still comes from live package, scenario, and security command parsing. Snapshot rendering calls DashboardLoader().loadSync() directly, so a visual proof path can still accidentally depend on live local command output even if Tessl fixture variables are set.

Evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:144
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:170
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:312
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:370
- Sources/SkillsBar/Support/Snapshot.swift:17-22
- Sources/SkillsBar/Services/DashboardLoader.swift:340-360
- Sources/SkillsBar/Services/DashboardLoader.swift:413-444

Smallest remediation:
- Add a spec note or implementation-plan requirement for one explicit fixture seam, for example DashboardLoader.reviewFixtureDashboard() selected by SKILLSBAR_REVIEW_FIXTURE=1 before running live package/scenario/security commands.
- Require SnapshotRenderer to honor the same fixture seam, so final-polish snapshot proof is deterministic and separate from live evidence.
- Keep Tessl fixture support as registry-only; do not overload it to fake local review state.

### P1. Canonical command remains intentionally unresolved, but the implementation route can still choose the wrong existing command

The spec correctly blocks closeout on the canonical inspect command. The architecture risk is that the existing code already exposes several plausible commands: selectedSkillInspectCommand reads the skill with sed, security.inspectCommand runs risk-modes JSON/robot, CommandDock can open registry, launch Terminal, copy recovery commands, or copy security commands. Without a named model property, an implementer can satisfy the visible label while binding copy behavior to the wrong existing command.

Evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:138-143
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:377-382
- Sources/SkillsBar/Models/DashboardModels.swift:81-86
- Sources/SkillsBar/Views/DashboardView.swift:715-813
- Sources/SkillsBar/Services/DashboardLoader.swift:413-444

Smallest remediation:
- Add a required presentation property name to the spec, such as reviewInspectCommand, and require the action block, visible command preview, accessibility value, and pasteboard assertion to bind to that property.
- Before implementation closeout, decide whether reviewInspectCommand is the current risk-modes command or a shorter human-facing inspect command. Until that decision exists, SA-007 and SA-013 remain blocked.

### P1. Popover point-size and height-fit acceptance are still open despite fixed current metrics

The current MenuBarExtra shell is correct, but it hard-codes a 356 x 560 point frame. The spec correctly says the bitmap must not be matched literally, yet the target point size is still an open question. That leaves implementers choosing between keeping current metrics, resizing blindly, or adding scroll behavior without an explicit acceptance target.

Evidence:
- Sources/SkillsBar/App/SkillsBarApp.swift:15-24
- Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:3-5
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:148
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:203
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:311
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:379-382

Smallest remediation:
- Choose a named implementation target before code closeout, for example MenuBarTemplateMetrics.reviewPopoverWidth and reviewPopoverHeight with a documented target-display proof.
- If the chosen height cannot show all required content, specify the scroll boundary: status/header, local trigger, bridge, and copy action must remain reachable and not be removed.

### P2. Details button behavior has an escape hatch but no inactive-state contract

FR-011 says the details icon opens details or inspection context if implemented, while the mockup shows the control as visible. The current code does not yet have the final-polish details button surface. If the destination remains unresolved, the implementation needs to know whether to omit, disable, or render a non-copy placeholder.

Evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:140
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:166
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:378

Smallest remediation:
- Add a fallback rule: if the details destination is not confirmed, either do not render the button in the live implementation or render it disabled with an accessible reason. It must not copy the inspect command or open registry as a substitute.

## Non-Findings

- No architecture conflict remains around the macOS shell. SkillsBarApp already uses MenuBarExtra with .menuBarExtraStyle(.window), and the spec now protects that boundary.
- No evidence suggests a NavigationSplitView, document window, sidebar, or normal WindowGroup is needed for this slice.
- The current score math can produce the target headline score 78 if the final fixture supplies quality 100, impact 71/71 as score 100, and security severities of 1 critical plus 2 high; the security penalty function yields 35, and the average rounds to 78.

## Validation Evidence

Command: nl -ba .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md | sed -n '1,260p' -> pass (inspected spec frontmatter, BLUF, scope, requirements, and architecture boundary)
Command: nl -ba .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md | sed -n '256,520p' -> pass (inspected lenses, validation plan, acceptance criteria, implementation notes, open questions, and handoff)
Command: nl -ba .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md | sed -n '1,180p' -> pass (inspected first three-lane synthesis and validation route)
Command: nl -ba README.md | sed -n '70,120p' -> pass (confirmed final-polish media routing is documented)
Command: nl -ba Sources/SkillsBar/App/SkillsBarApp.swift | sed -n '1,80p' -> pass (confirmed MenuBarExtra(.window) shell)
Command: nl -ba Sources/SkillsBar/App/MenuBarTemplateMetrics.swift | sed -n '1,80p' -> pass (confirmed current fixed popover metrics)
Command: nl -ba Sources/SkillsBar/Views/DashboardView.swift | sed -n '1,120p' -> pass (inspected current dashboard composition)
Command: nl -ba Sources/SkillsBar/Views/DashboardView.swift | sed -n '700,875p' -> pass (inspected current CommandDock/PrimaryAction command routing)
Command: nl -ba Sources/SkillsBar/Models/DashboardModels.swift | sed -n '1,120p' -> pass (inspected command and computed state properties)
Command: nl -ba Sources/SkillsBar/Services/DashboardLoader.swift | sed -n '340,450p' -> pass (inspected fixture and local signal seams)
Command: nl -ba Sources/SkillsBar/Support/Snapshot.swift | sed -n '1,80p' -> pass (inspected snapshot loading path)
Command: live MenuBarExtra runtime review -> blocked (no running app screenshot, click/pasteboard proof, focus traversal, reduced-motion mode, or height measurement was performed in this pass)

## Status

STATUS: findings_remaining

The spec did absorb the first review's architecture findings, but the deterministic fixture seam, canonical command property, popover point-size target, and details-button fallback still need tightening before an implementation can be reviewed with no further architecture conflicts.
