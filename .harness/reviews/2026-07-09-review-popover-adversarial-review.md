# Adversarial Review: Final-Polish Review Popover Refactor

schema_version: 1
reviewer: adversarial-reviewer
target: SkillsBar macOS MenuBarExtra review popover
spec_path: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
visual_target: .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png
status: review_complete_with_blockers

## Bottom Line

The spec is strong enough to drive a refactor, but the current SwiftUI implementation is still structurally the earlier dashboard/comparison surface, not the final-polish review popover. The highest implementation risk is trying to skin the existing DashboardView instead of replacing its information architecture with the spec sequence: header, identity, expanded local review trigger, secondary registry row, mixed bridge, and one neutral copy action. The implementation should block closeout until it proves the canonical command, fixture-backed target state, live MenuBarExtra height, clipboard, focus, and reduced-motion behavior.

## Severity-Ranked Findings

### P0. The current DashboardView information architecture cannot satisfy the final-polish spec by styling alone

Evidence:
- Spec requires the sequence and semantics of a final-polish review popover: local review trigger expanded, registry secondary, mixed bridge, and one copy action at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:126, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:128, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:131, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:132, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:133.
- Current DashboardView renders the older dashboard stack: HeaderScoreView, SkillIdentityView, ProofLaneComparisonView, FleetSummaryView, LocalChecksPanel, SecurityBlock, and CommandDock at Sources/SkillsBar/Views/DashboardView.swift:12 through Sources/SkillsBar/Views/DashboardView.swift:24.
- The current proof-lane table renders local and registry rows as peers under a Source / Score / Impact / Security header at Sources/SkillsBar/Views/DashboardView.swift:183 through Sources/SkillsBar/Views/DashboardView.swift:229, which conflicts with the spec's local-first, registry-secondary visual hierarchy.
- The current implementation still has a fleet inventory row and copy button at Sources/SkillsBar/Views/DashboardView.swift:406 through Sources/SkillsBar/Views/DashboardView.swift:435; the final-polish spec has no fleet row in the resting target.

Implementation-risk implication:
An implementation that keeps ProofLaneComparisonView, FleetSummaryView, and SecurityBlock may look dense and useful but will violate SA-002, SA-004, SA-005, SA-006, SA-011, and SA-012 because it never creates the single expanded Review trigger card and mixed bridge flow.

Smallest remediation:
Create a dedicated review-popover composition inside the existing MenuBarExtra(.window) scene, replacing the current child stack for the review state. Keep reusable primitives only where they map to the final target: logo loaders, Hexagon, CopyFeedbackModel, status colors, and model values. Do not preserve the proof-lane table as the primary layout.

Validation proof needed:
Command: SNAPSHOT_OUT=/tmp/skillsbar-final-polish.png <repo-owned snapshot command> -> pass|fail|blocked (<reason>), followed by visual comparison against .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png.

### P0. The canonical copy command is still unresolved, but current code already copies a security command under the primary action

Evidence:
- Spec marks the mockup command as non-authoritative and blocks closeout until the exact command is confirmed at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:78, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:92, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:135, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:356.
- Current primary action command switches to dashboard.security.inspectCommand when security is flagged at Sources/SkillsBar/Views/DashboardView.swift:720 through Sources/SkillsBar/Views/DashboardView.swift:722.
- Current loader builds the security command from ./bin/ask sdk security risk-modes <skill> --preview --json --robot at Sources/SkillsBar/Services/DashboardLoader.swift:19 through Sources/SkillsBar/Services/DashboardLoader.swift:20, then wraps it with cd <root> && at Sources/SkillsBar/Services/DashboardLoader.swift:31 through Sources/SkillsBar/Services/DashboardLoader.swift:32.
- The final-polish visual displays cd .../agent-skills && ./bin/ask sdk security risk-modes Skills/agent-ops/improve-agent-native --preview, omitting --json --robot; the spec says that placeholder must not ship if unsupported.

Implementation-risk implication:
The app could pass a visual screenshot with a two-line command preview while copying a different command string than the user expects, or conversely copy the full JSON/robot command while visually promising an operator-friendly inspect command. That violates the user scenario at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:61 and SA-007.

Smallest remediation:
Add a named command model property for the final copy action, for example reviewInspectCommand, with an explicit display string and copy string if they intentionally differ. Confirm whether the copy target is the existing JSON/robot risk-modes command or a shorter human inspect command, then bind both the action label and pasteboard test to that source.

Validation proof needed:
Run a clipboard-level test in a fixture state: click the copy action in the MenuBarExtra popover, read NSPasteboard.general.string(forType: .string), and assert exact equality with the canonical command source.

### P1. There is no fixture-backed way to produce the exact spec state: score 78, 71/71, three risks, registry score 66, 68 evals

Evidence:
- Spec hard-codes required state values at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:126 through .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:133 and .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:166 through .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:176.
- Current local score is computed as the rounded average of quality, impact, and security scores at Sources/SkillsBar/Models/DashboardModels.swift:50 through Sources/SkillsBar/Models/DashboardModels.swift:55.
- Current security score is derived from severity penalties at Sources/SkillsBar/Services/DashboardLoader.swift:457 through Sources/SkillsBar/Services/DashboardLoader.swift:468; for one critical and two high findings this produces 100 - 65 = 35, not the spec/header score 78.
- Current Tessl fixtures only cover registry fields via environment variables at Sources/SkillsBar/Services/DashboardLoader.swift:339 through Sources/SkillsBar/Services/DashboardLoader.swift:360. There is no equivalent fixture injection for local quality, impact, security risk count, or severity details.

Implementation-risk implication:
The team may have to choose between honest dynamic model output and the mockup's curated state. Without a fixture, screenshot validation can become flaky or impossible because live local commands may not yield 78, 71/71, and 3 risks.

Smallest remediation:
Introduce a review-popover preview/fixture path for the exact approved state, separate from live command parsing. Use it for snapshot comparison and UI tests. Keep live data parsing intact, but do not use live command availability as the only way to render the target design state.

Validation proof needed:
Add a snapshot fixture command or launch environment that deterministically renders the spec state, including local review fixture variables plus TESSL_REGISTRY_FIXTURE_SCORE=66, TESSL_REGISTRY_FIXTURE_VERSION=0.2.0, TESSL_REGISTRY_FIXTURE_QUALITY=100, TESSL_REGISTRY_FIXTURE_IMPACT=63, TESSL_REGISTRY_FIXTURE_SECURITY=passed, and TESSL_REGISTRY_FIXTURE_EVALS=68.

### P1. The fixed MenuBarExtra frame is smaller than the persisted visual target and has no height-fit proof strategy

Evidence:
- App constrains the MenuBarExtra content to MenuBarTemplateMetrics.width and MenuBarTemplateMetrics.height at Sources/SkillsBar/App/SkillsBarApp.swift:16 through Sources/SkillsBar/App/SkillsBarApp.swift:24.
- Current metrics are width = 356 and height = 560 at Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:3 through Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:5.
- The persisted final-polish mockup is 975 x 1614 pixels, shown by file .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png; at 2x this implies roughly 487.5 x 807 points, not 356 x 560.
- Spec explicitly lists height fit as a risk and validation gate at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:45, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:142, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:298, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:311.

Implementation-risk implication:
Blindly matching the generated image proportions may exceed comfortable laptop popover height; keeping the existing 356 x 560 may force compression that loses required rows or clips content. Either failure can satisfy a static code review while failing the real MenuBarExtra surface.

Smallest remediation:
Decide target point dimensions for the MenuBarExtra window before implementation closeout. If the app must stay near 356 x 560, the spec needs a compact native adaptation rule; if it grows, validate on the target laptop screen and document any internal scroll or spacing compression.

Validation proof needed:
Runtime MenuBarExtra screenshot on target display with measured window bounds, plus a check that status, local trigger, bridge line, and action are all visible without scrolling unless scrolling is explicitly approved.

### P1. Menu-bar-specific anchoring and materialization are underspecified relative to SwiftUI control

Evidence:
- The app uses MenuBarExtra with .menuBarExtraStyle(.window) at Sources/SkillsBar/App/SkillsBarApp.swift:15 through Sources/SkillsBar/App/SkillsBarApp.swift:24.
- Spec requires popover materialization from the menubar item origin and reduced-motion crossfade at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:149, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:150, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:162.
- Current DashboardView has no animation, reduced-motion, or accessibility reduce-motion handling surfaced in code; search evidence found no accessibilityReduceMotion, withAnimation, or environment-driven motion controls in Sources/SkillsBar.

Implementation-risk implication:
SwiftUI MenuBarExtra(.window) controls the system window/popover presentation. A custom view-level scale or blur may not truly originate from the menu bar icon and may introduce transform-heavy motion that cannot be disabled. Conversely, no view-level motion may be acceptable if the system presentation owns it, but the spec currently says SHOULD without stating what is feasible in MenuBarExtra.

Smallest remediation:
Keep the implementation inside MenuBarExtra(.window), but make the motion contract concrete: either rely on native system presentation and document that app code does not add transform motion, or add only internal material opacity transitions guarded by @Environment accessibilityReduceMotion.

Validation proof needed:
Record a live open/close capture or reduced-motion inspection. At minimum, verify code has no unguarded transform animation and run the app with reduced motion enabled.

### P1. Current copy controls do not prove visible focus or pointer-down feedback in a menu-bar popover

Evidence:
- Spec requires keyboard traversal, accessible names, and visible keyboard focus for details and copy controls at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:62, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:159, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:160, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:309.
- CopyIconButton uses .buttonStyle(.plain), a small 19 x 19 image frame, and .accessibilityLabel(help) at Sources/SkillsBar/Views/DashboardView.swift:1073 through Sources/SkillsBar/Views/DashboardView.swift:1088.
- The visible state changes only after copying via feedback.copiedCommand, not on pointer-down or focus, at Sources/SkillsBar/Views/DashboardView.swift:1071 through Sources/SkillsBar/Views/DashboardView.swift:1085.

Implementation-risk implication:
Plain icon buttons may be keyboard reachable but not visibly focused in a dark translucent menu-bar window, and they may feel inert until mouse-up. This violates Apple Design response guidance and SA-008 even if VoiceOver sees a label.

Smallest remediation:
For the final copy/details controls, provide an explicit focus ring or focus background using @FocusState or platform focus styling that is visible against the graphite surface. Add pressed-state feedback for the icon buttons. Keep hit targets larger than the visible glyph even if the mockup glyph is compact.

Validation proof needed:
Keyboard traversal capture or accessibility audit showing focus order: menu trigger -> details button -> copy button, with visible focus state and stable command field layout.

### P2. README still points to the superseded mockup and can route future agents to stale visual evidence

Evidence:
- README project layout lists .harness/media/2026-07-09-skills-sdk-menubar-final-mockup.png at README.md:102 through README.md:104.
- Spec says the final-polish mockup supersedes earlier generated alternatives at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:185, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:317 through .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:329.

Implementation-risk implication:
An implementation agent following README before the spec may compare against the wrong image and regress to the earlier visual direction.

Smallest remediation:
When implementation work begins, update README project layout to name the final-polish mockup or explicitly call the older image historical.

Validation proof needed:
Command: rg -n "2026-07-09-skills-sdk-menubar-final-mockup|review-popover-final-polish" README.md .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md -> pass.

### P2. Header semantics are still local-score driven, but the spec now frames the hex as a Tessl-style review score emblem

Evidence:
- Spec requires a Tessl-style hex score 78 in the header and says the header icon must not compete with the hex at .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:126, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:138, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:313.
- Current ScoreEmblemView accessibility label names it Local score at Sources/SkillsBar/Views/DashboardView.swift:178 through Sources/SkillsBar/Views/DashboardView.swift:179.
- Current scoreCaption returns Local at Sources/SkillsBar/Models/DashboardModels.swift:65 through Sources/SkillsBar/Models/DashboardModels.swift:67.

Implementation-risk implication:
If carried forward, assistive tech and visible captions can contradict the final-polish visual language (review score) and the spec's score-emblem semantics.

Smallest remediation:
Rename score semantics for the final state to review score while preserving model separation between local evidence and registry evidence. The accessible label should say the status and score, not imply registry safety.

Validation proof needed:
Accessibility snapshot or manual VoiceOver pass for the header score.

## Suggested Refactor Shape

Do:
- Keep MenuBarExtra(.window) in Sources/SkillsBar/App/SkillsBarApp.swift.
- Replace the current DashboardView review-state body with a new composed layout matching the spec order.
- Keep or refactor small primitives: Hexagon, logo loaders, CopyFeedbackModel, command model, StatusTone.
- Add deterministic fixture support for the exact final-polish state before relying on screenshot comparison.
- Add a snapshot path that renders the fixture state at the chosen MenuBarExtra point size.

Do not:
- Do not introduce a normal app window, NavigationSplitView, or broader window-scene restructuring.
- Do not preserve ProofLaneComparisonView as the main comparison surface.
- Do not show fleet inventory in the final review popover resting state.
- Do not use a pure green check for the bridge row.
- Do not claim generated-image match as live UI proof.

## Validation Boundaries

Commands/evidence reviewed:
- Command: git status --short --branch -> pass (worktree has existing spec/media changes and untracked skill install paths)
- Command: rg --files | rg required review paths -> pass (required files located, then expanded to services/support/tests)
- Command: file .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png -> pass (PNG image data, 975 x 1614)
- Command: view_image(path=/Users/jamiecraik/dev/skillsbar/.harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png, detail=high) -> pass (reviewed visible static target)
- Command: live MenuBarExtra runtime review -> blocked (not run by this review agent; no live popover screenshot, focus traversal, pasteboard click, reduced-motion, or height measurement)
- Command: swift build/test -> blocked (not needed for this read-only adversarial review; implementation has not changed in this subtask)

## Residual Risk

- This review is static and adversarial. It does not prove the app currently builds, launches, or renders the target.
- Line evidence proves implementation/spec mismatches and risk gates, not the exact remediation cost.
- The generated image remains a visual target, not a UI test oracle; live screenshot comparison needs a deterministic fixture and tolerance rules.
