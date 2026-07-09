# Agent-Native Pass 2: Review Popover Spec Handoff

schema_version: 1
date: 2026-07-09
reviewer: agent-native-reviewer-pass2
target_spec: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
target_surface: SkillsBar macOS MenuBarExtra(.window) review popover
visual_target: .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png

## Bottom Line

The first-pass review findings were substantially folded into the spec: MenuBarExtra(.window) is now an explicit boundary, the final-polish mockup is the current visual target, registry/local truth is separated in requirements, the review-state action is copy-only, and deterministic fixture proof is required. A future implementation agent has enough direction to avoid the main wrong architecture and wrong visual target, but not enough to close the implementation without three remaining handoff fixes: canonical inspect-command ownership, an exact snapshot invocation contract, and a local fixture data contract that maps the required final-polish values to model fields.

## What Was Implemented Into The Spec

- Menu-bar shell preservation is explicit. The spec says this is a macOS MenuBarExtra(.window) popover and forbids WindowGroup, NavigationSplitView, document-window, sidebar, or standalone app-window architecture at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:110 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:159.
- Final-polish media routing is explicit. The spec names the final-polish mockup and prompt sidecar at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:27-32 and displays the final-polish image at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:118-124. README also routes agents to the final-polish media at README.md:102-104.
- Copy-only review-state behavior is explicit. FR-014 requires the Needs review primary action to copy the canonical inspect command and not open Tessl, Terminal, or a recovery command at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:143.
- Deterministic final-polish fixture proof is now required. FR-015, SA-014, and V-009 require fixture-backed rendering for the exact final-polish state at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:144, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:312, and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:330.
- The mixed registry/local bridge is explicit. FR-012 and SA-011 require success plus local-warning semantics instead of pure green success at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:141 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:327.
- The first-pass synthesis now gives implementation agents a component boundary and validation route at .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:113-140.

## Remaining Issues

### P0. Canonical inspect command is still a blocker, not an implementation-ready contract

Finding:
The spec repeatedly says the copied command must be canonical, but it also names the canonical command as unresolved. That is honest, but it means an implementation agent cannot truthfully satisfy SA-007 or SA-013 without another product decision or a spec amendment choosing the command source.

Evidence:
- The spec's current-state table marks canonical inspect command unresolved at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:94.
- The command summary says implementation planning should wait until the exact command string is confirmed at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:48.
- FR-009 and FR-010 require full canonical copy behavior and forbid shipping the placeholder command at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:138-139.
- Open questions still ask whether to copy the current JSON/robot risk-modes command or a shorter human-facing inspect command at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:377 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:381.
- The current implementation has multiple plausible command sources: selectedSkillInspectCommand reads SKILL.md at Sources/SkillsBar/Models/DashboardModels.swift:84-86, while security.inspectCommand is built from risk-modes at Sources/SkillsBar/Services/DashboardLoader.swift:413-444.

Impact:
Without resolving this, one agent may implement the visible label Copy inspect command against security.inspectCommand, while another may implement it against selectedSkillInspectCommand or a new human-facing command. Both can appear compliant in UI review but fail pasteboard trust.

Smallest guardrail:
Add one spec line under Data / Domain Contract: review_inspect_command equals the exact command string or exact model property. If the decision is to use the current risk-modes command, name SkillDashboard.reviewInspectCommand as a derived presentation property sourced from SecuritySignal.inspectCommand. If the decision is to inspect SKILL.md, name SkillDashboard.selectedSkillInspectCommand and update the action subtitle away from security-risk language.

### P1. Snapshot validation route still contains a placeholder command

Finding:
The spec and synthesis require fixture snapshot proof, but the command is still expressed as placeholder snapshot command. The repo already has a snapshot argument parser and a launcher path, so implementation agents need an exact command shape or an explicit instruction to add one.

Evidence:
- The validation route still uses placeholder snapshot command at .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:132.
- Snapshot.swift already accepts --snapshot <path> and renders DashboardView at Sources/SkillsBar/Support/Snapshot.swift:5-12 and Sources/SkillsBar/Support/Snapshot.swift:15-34.
- README validation lists build, Launch.command, tests, and live verify, but does not document the snapshot command at README.md:67-90.
- The spec validation plan marks V-009 as blocked until fixture exists, but does not specify whether the snapshot is run via swift run SkillsBar --snapshot, the built app executable, or Launch.command at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:299-313.

Impact:
Agents can add fixture support but still leave visual proof non-reproducible because the executable path and environment contract are not durable.

Smallest guardrail:
Add an exact blocked-until-implemented command to the spec, for example:
SKILLSBAR_REVIEW_FIXTURE=1 TESSL_REGISTRY_FIXTURE=1 TESSL_REGISTRY_FIXTURE_SCORE=66 TESSL_REGISTRY_FIXTURE_VERSION=0.2.0 TESSL_REGISTRY_FIXTURE_QUALITY=100 TESSL_REGISTRY_FIXTURE_IMPACT=63 TESSL_REGISTRY_FIXTURE_SECURITY=Passed TESSL_REGISTRY_FIXTURE_EVALS=68 swift run --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-snapshot-build SkillsBar --snapshot /private/tmp/skillsbar-final-polish.png
If SwiftPM cannot run the executable with that syntax in this package, replace it with the proven built executable path after NO_OPEN=1 ./Launch.command.

### P1. Local fixture requirements name values but not model-field ownership

Finding:
The spec requires the final-polish fixture values, but it does not map those values to concrete SkillDashboard, MetricSignal, SecuritySignal, and TesslSignal fields. Tessl fixture support exists; local fixture support does not.

Evidence:
- Required values are listed in Data / Domain Contract at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:172-184.
- Tessl fixture env vars already map to TesslSignal fields at Sources/SkillsBar/Services/DashboardLoader.swift:339-360.
- Local impact and security values currently derive from command payload parsing at Sources/SkillsBar/Services/DashboardLoader.swift:382-455.
- The model score is currently computed as the average of quality, impact, and security scores at Sources/SkillsBar/Models/DashboardModels.swift:50-55, so a desired header score of 78 requires explicit local fixture scoring behavior, not just text labels.

Impact:
An implementation can render the visible text as constants in the view, bypass the model, and still appear to match the mockup. That would weaken agent-native proof because snapshot output would no longer prove the domain model supports the state.

Smallest guardrail:
Add a fixture mapping table to the spec:
- SkillDashboard.displayName = improve-agent-native
- SkillDashboard.registryPath = jscraik/improve-agent-native
- SkillDashboard.description = Private live eval plugin for improve-agent-native.
- quality.score = 100
- impact.score = 100 with impact.statusOverride = 71/71
- security.status = Flagged, security.detail = 3 risk modes: 1 critical, 2 high., security.score = 35 or another explicit value that yields header score 78
- tessl.registryScore = 66, registryVersion = 0.2.0, registryQualityScore = 100, registryImpactScore = 63, registrySecurityLabel = Passed, registryEvalCount = 68
If the score formula cannot yield 78 from these semantic fields, the spec should authorize a presentation score override for review state.

### P2. README points to the final-polish artifact but not the implementation handoff rules

Finding:
README now lists the final-polish media path, which resolves the first-pass routing issue. It does not point future agents to the three-lane synthesis or name the copy/fixture/MenuBarExtra blockers, so a fresh implementation agent reading README and AGENTS may still need to rediscover the review artifacts.

Evidence:
- README lists the spec and final-polish media paths at README.md:102-104.
- AGENTS tells UI/behavior agents to check the spec and referenced mockup at AGENTS.md:15-18.
- The three-lane synthesis has the implementation component boundary and validation route at .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:113-140, but README does not route to it.

Impact:
This is not blocking because the spec cites the synthesis in Evidence and References, but direct README routing would reduce hidden-context risk for agents starting from project docs.

Smallest guardrail:
Add the synthesis path to README Project Layout or Development Notes and state that implementation should follow the spec first, then the synthesis for component boundaries and validation route.

## Current Agent-Native Handoff Verdict

safe_to_continue: true for implementation planning and code exploration.

safe_to_close_implementation: false until the canonical command, exact snapshot command, local fixture mapping, and live MenuBarExtra proof are resolved.

No new architecture conflict found. The MenuBarExtra boundary is now clear enough to prevent normal-window drift.

## Validation Evidence

Command: rg over spec, synthesis, docs, launcher, snapshot, and Swift sources -> pass (review discovery found updated spec, synthesis, docs, launcher, snapshot, and SwiftUI/model surfaces)

Command: nl -ba .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md | sed -n '1,220p' -> pass (confirmed final-polish, MenuBarExtra, copy-only, fixture, and acceptance requirements in the updated spec)

Command: nl -ba .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md | sed -n '220,520p' -> pass (confirmed validation plan, acceptance IDs, open questions, and proof/runtime boundary)

Command: nl -ba Sources/SkillsBar/Support/Snapshot.swift | sed -n '1,220p' -> pass (confirmed existing snapshot renderer argument and output behavior)

Command: nl -ba Sources/SkillsBar/Services/DashboardLoader.swift | sed -n '339,365p' -> pass (confirmed Tessl fixture env var support exists)

Command: nl -ba Sources/SkillsBar/Services/DashboardLoader.swift | sed -n '380,460p' -> pass (confirmed local impact and security currently derive from command payloads and lack a final-polish local fixture path)

Command: nl -ba Sources/SkillsBar/Models/DashboardModels.swift | sed -n '1,240p' -> pass (confirmed current score formula and command-bearing model properties)

Command: live MenuBarExtra runtime review -> blocked (not run in this pass; no live app screenshot, pasteboard click, focus traversal, reduced-motion check, or height measurement was produced)
