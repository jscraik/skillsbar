# Review Popover Architecture Review

schema_version: 1
reviewer: architecture-strategist
target_spec: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
target_surface: SkillsBar MenuBarExtra(.window) review popover
status: completed
mode: architecture-refactor-review
generated_at: 2026-07-09
route:
  - build-macos-apps:swiftui-patterns
  - build-macos-apps:build-run-debug
  - apple-design
  - improve-agent-native
  - testing

## Bottom Line

Refactor the current implementation by preserving the existing macOS menu-bar app shell and replacing the dashboard-style interior with a narrative review-popover component stack. The scene architecture is already correct for this product: SkillsBarApp uses MenuBarExtra with DashboardView and .menuBarExtraStyle(.window), so the implementation should not introduce a normal WindowGroup, navigation shell, sidebar, or document-style app. The refactor should concentrate on DashboardView.swift, a small presentation model layer in DashboardModels.swift, fixture-backed loader values in DashboardLoader.swift, stable metrics in MenuBarTemplateMetrics.swift, copy/focus affordances, and snapshot/live launch proof.

## Evidence Read

- AGENTS.md:1-47 says SkillsBar is a live local macOS SwiftUI menu-bar prototype and UI work must check the review-popover spec before changing semantics.
- AGENTS.md:49-73 gives the repo-native build, launch, test, and live UI proof commands and requires exact Command evidence reporting.
- README.md:1-14 defines the product as a native macOS menu-bar app that separates local SDK evidence from Tessl registry evidence.
- README.md:82-93 identifies the spec and mockup media as the UI context.
- Package.swift:5-14 is a SwiftPM macOS 14 package with one executable target, app resources, and a core test target.
- Sources/SkillsBar/App/SkillsBarApp.swift:13-24 uses MenuBarExtra, passes DashboardModel into DashboardView, frames it with MenuBarTemplateMetrics, and applies .menuBarExtraStyle(.window).
- Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:3-5 currently fixes the popover at 356 x 560.
- Sources/SkillsBar/Views/DashboardView.swift:12-24 composes the current popover as header, skill identity, proof-lane table, fleet summary, local checks, security block, action dock.
- Sources/SkillsBar/Views/DashboardView.swift:183-318 implements a comparison-table pattern that does not match the final mockup's narrative local-card/registry-row/bridge flow.
- Sources/SkillsBar/Views/DashboardView.swift:406-435 adds FleetSummaryView, which is useful agent-native evidence but out of scope for the final-polish mockup's primary story.
- Sources/SkillsBar/Views/DashboardView.swift:438-478 has reusable metric-column material for quality/impact/security that can be retained inside a new local review trigger card.
- Sources/SkillsBar/Views/DashboardView.swift:537-567 implements package identity with repo/title/description but currently uses registryPath and displayName, not the spec's jscraik/improve-agent-native plus Private pill copy.
- Sources/SkillsBar/Views/DashboardView.swift:715-813 has the existing copy/action dock, but it currently changes primary behavior depending on security/Tessl state and can open the registry; the spec needs one neutral Copy inspect command action.
- Sources/SkillsBar/Views/DashboardView.swift:1065-1088 centralizes copy-button behavior through CopyFeedbackModel, which is the right source for clipboard state but needs focus styling and stable sizing.
- Sources/SkillsBar/Models/DashboardModels.swift:50-86 already computes aggregate score, source labels, registry URL/search command, and selectedSkillInspectCommand.
- Sources/SkillsBar/Models/DashboardModels.swift:114-129 computes the header verdict from security status and Tessl state.
- Sources/SkillsBar/Models/DashboardModels.swift:336-407 models security display, severity line, score math, penalty line, and accessibility text.
- Sources/SkillsBar/Models/DashboardModels.swift:410-599 models Tessl registry fields and display labels, including score, version, quality, impact, security, eval count, and comparison labels.
- Sources/SkillsBar/Services/DashboardLoader.swift:339-360 already supports Tessl fixture environment variables for mockup/snapshot proof.
- Sources/SkillsBar/Services/DashboardLoader.swift:413-477 parses local security risk modes and severity summary, making 3 risks / 1 critical, 2 high feasible without inventing a new source.
- Sources/SkillsBar/Support/Snapshot.swift:15-34 can render DashboardView to PNG via --snapshot, giving a low-friction static proof lane after implementation.
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:126-138 defines the final functional requirements for header, package identity, local card, registry row, bridge line, action, details button, mixed glyph, and hierarchy.
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:142-152 defines the macOS material, motion, icon, and stable command-preview constraints.
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:286-313 defines validation and acceptance IDs SA-001 through SA-012.

## Architecture Decision

Keep the app shell unchanged:

- Keep MenuBarExtra(.window) as the only primary scene.
- Keep DashboardModel as the app-owned observable store.
- Keep DashboardLoader as the source of local/Tessl evidence.
- Keep CopyFeedbackModel as the shared clipboard feedback store.
- Keep SnapshotRenderer as the generated visual proof path.

Refactor the interior into a small set of explicit review-popover components. The current DashboardView.swift can remain the first implementation file for speed, but the resulting boundaries should be clear enough to split later if file size or ownership becomes noisy.

Recommended component stack:

1. ReviewPopoverView: owns the vertical narrative order and fixed frame padding; replaces the current dashboard composition at DashboardView.swift:12-24; inputs are DashboardModel or SkillDashboard only.
2. ReviewHeaderView: contains header app icon, product label, Needs review, substatus, top-right details button, and ScoreEmblemView; reuses Hexagon from DashboardView.swift:1141-1157; adjusts the badge into a quieter caption.
3. PackageIdentityBlock: shows jscraik/improve-agent-native, Private, and Private live eval plugin for improve-agent-native; uses registryPath, displayName, and description from DashboardModels.swift:32-48 where possible.
4. LocalReviewTriggerCard: replaces the separate proof-lane table, local checks, and security block stack; shows one auto-expanded local review card with warning rail, source pills, score row, divider, and three metric columns.
5. RegistryComparisonRow: replaces the registry half of ProofLaneComparisonView and the older TesslBlock; shows Tessl icon, registry path, version, score, and inline quality/impact/security summary.
6. RegistryLocalBridgeRow: new component for Registry clean. Local source has findings. and 68 registry eval scenarios; must use a mixed green success plus amber local-finding glyph.
7. InspectCommandActionBlock: replaces CommandDock behavior; always presents one neutral Copy inspect command action in review state; copies from a model command string, not rendered truncated text.

## Model And State Changes

Add presentation computed properties rather than a parallel loader contract. The loader already returns quality, impact, security, Tessl registry, fleet, and commands. Avoid duplicating source truth.

Recommended additions:

- SkillDashboard.packageVisibilityLabel -> Private for now, or derive it from metadata only if a real field exists.
- SkillDashboard.packageSubtitle -> Private live eval plugin for displayName.
- SkillDashboard.reviewCommandTitle -> Copy inspect command.
- SkillDashboard.reviewCommandSubtitle -> Inspect security.statusDisplay in SKILL.md with a specific branch for flagged security.
- SkillDashboard.inspectCommand -> security.inspectCommand for flagged state; otherwise selectedSkillInspectCommand.
- SkillDashboard.bridgeTitle -> Registry clean. Local source has findings. only when Tessl is clean and local security is flagged.
- SkillDashboard.bridgeDetail -> registry eval scenario count when available.
- SecuritySignal.riskCountText, riskSeverityText, and riskInspectSubtitle so views do not parse display strings.
- TesslSignal.registrySummaryLine for v0.2.0, score 66, Quality 100%, Impact 63%, Security Passed.

Rationale:

- DashboardLoader.swift:413-477 already owns severity parsing. Views should not re-parse severityLine.
- DashboardModels.swift:497-546 already owns registry display/tone logic. Views should consume these, not reinterpret raw optional fields.
- CopyFeedbackModel.swift:6-15 already owns clipboard feedback; the action block should consume it without new global state.

## Fixture Strategy

The spec requires a deterministic visual state: local score 78, quality 100%, impact 71/71, security 3 risks, registry score 66, registry quality 100%, registry impact 63%, registry security Passed, evals 68.

Current fixture coverage: Tessl fixture values are supported by DashboardLoader.swift:339-360, but local values depend on live ./bin/ask command output.

Recommendation:

- Add SKILLSBAR_REVIEW_FIXTURE=1 in DashboardLoader.load() or a small ReviewFixtureDashboard factory.
- Keep it test/snapshot-only and document it as UI proof fixture, not production truth.
- Use it in SnapshotRenderer and app launch verification when comparing the final mockup.

## File-Level Refactor Plan

### Sources/SkillsBar/App/SkillsBarApp.swift

Keep the scene model. Preserve MenuBarExtra and .menuBarExtraStyle(.window) at SkillsBarApp.swift:13-24. Do not add WindowGroup, navigation containers, or AppKit popover replacement unless SwiftUI cannot express a required behavior.

### Sources/SkillsBar/App/MenuBarTemplateMetrics.swift

Increase or confirm the popover dimensions against the final-polish mockup. Current 356 x 560 may be too narrow/tight for the final command block and long repo path. Convert constants into named values such as popoverWidth, popoverHeight, commandPreviewHeight, and iconButtonSize. Validate against snapshot and live menubar height before accepting.

### Sources/SkillsBar/Views/DashboardView.swift

Primary refactor target. Replace DashboardView.body with the final narrative stack. Keep useful primitives: PopoverInteriorBackdrop, ScoreEmblemView after simplification, MetricBarColumn, TesslLogoView, SkillsSDKLogoView after variant tuning, CopyIconButton after focus/size/accessibility tuning, Hexagon, and color tokens. Retire or stop rendering ProofLaneComparisonView, FleetSummaryView, SecurityBlock, TesslBlock, PrimaryAction, InstallCommand, and FooterBar for this review state. Add accessibilityElement(children: .combine) and explicit labels to local card, registry row, bridge row, details button, and command preview. Add focus styling because buttonStyle(.plain) can erase native focus cues.

### Sources/SkillsBar/Views/SkillsMenuBarIconView.swift

Keep the menu-bar icon separate. It already loads SkillsSDKIconLoader.menuBarImage and falls back to SF Symbols. Make optical variants explicit rather than relying on one resized source image: menuBarImage, headerImage, and rowImage, or a renderer that accepts target role/size. Keep 23x23 unless live menu-bar proof shows crowding.

### Sources/SkillsBar/Models/DashboardModels.swift

Add presentation helpers and keep data semantics intact. Keep aggregate score calculation at DashboardModels.swift:50-55 unless product decides a different local score formula. Do not change TesslSignal.ok semantics. Do not treat registry Passed as local security proof. Do not hardcode mockup values outside fixture mode.

### Sources/SkillsBar/Services/DashboardLoader.swift

Keep real command execution at DashboardLoader.swift:45-81. Add deterministic fixture support behind an env var. Do not replace real local evidence loading with static data and do not add network dependencies to snapshot validation.

### Sources/SkillsBar/Stores/CopyFeedbackModel.swift

Keep the store. It is already small and focused. Consider exposing a copy result state if validation needs visible copied feedback. The existing 1.2s reset is reasonable.

### Sources/SkillsBar/Support/Snapshot.swift

Use this as the first implementation proof lane. Allow fixture mode through environment. Write snapshots to .harness/media/runtime/ or /private/tmp unless persistence is explicitly requested.

## Apple Design Constraints To Carry Into Code

- Popover material must remain restrained graphite, not stacked bright glass.
- Native MenuBarExtra owns most opening behavior; do not fake a large in-popover animation that fights the system popover.
- Use critically damped, no-bounce feedback for internal state changes.
- Icon buttons must respond on press and show visible keyboard focus.
- Reduced motion should disable custom scale/slide transitions. If no custom transitions are added, document that native MenuBarExtra owns this lane and verify in live UI.
- Typography should use system font, stable line limits, minimum scale factors, and contrast checks for small text.

## Agent-Native And Proof Guardrails

- Keep local SDK, Tessl registry, live UI, hosted CI, and implementation readiness as separate lanes.
- The copy command is the highest trust surface. It must be a canonical command from DashboardLoader or a derived model field, not text copied from the command preview.
- Use fixture-backed snapshots to keep agent review reproducible.
- Preserve the exact command evidence shape required by AGENTS.md.

## Risks

1. Scene drift risk: implementation may overreact to the mockup and create a normal window app. Evidence: SkillsBarApp.swift:13-24 already has the correct menu-bar scene. Mitigation: explicitly forbid WindowGroup/navigation refactor for this slice.
2. Dashboard residue risk: old dashboard elements remain visible and compete with the final local-review story. Evidence: DashboardView.swift:16-23 still renders proof comparison, fleet summary, local checks, security, and action dock. Mitigation: replace the rendered stack rather than adding the new mockup under the old stack.
3. Command trust risk: action copies the wrong command or opens registry when review state expects local inspection. Evidence: CommandDock switches behavior at DashboardView.swift:750-763. Mitigation: create a dedicated review-state action block that always copies the model's inspect command.
4. Fixture/proof gap risk: final mockup values cannot be reproduced reliably from live data. Evidence: Tessl fixture exists at DashboardLoader.swift:339-360, but local values still come from command output. Mitigation: add a local review fixture env var for snapshot/visual proof.
5. Accessibility gap risk: plain icon buttons lack visible focus or meaningful accessible values. Evidence: CopyIconButton uses .buttonStyle(.plain) and only accessibilityLabel(help) at DashboardView.swift:1065-1088. Mitigation: add focusable button styling and full command accessible value/label.
6. Height fit risk: final narrative popover clips on laptop displays. Evidence: spec NFR-001 and validation V-008; current fixed height is 560. Mitigation: snapshot at target metrics, live-launch check, and compress identity/card gaps before deleting required rows.

## Implementation Sequence

1. Add deterministic review fixture path with SKILLSBAR_REVIEW_FIXTURE=1.
2. Add presentation helpers to models for bridge text, action labels, package visibility/subtitle, risk details, and registry summary.
3. Refactor DashboardView composition into ReviewHeaderView, PackageIdentityBlock, LocalReviewTriggerCard, RegistryComparisonRow, RegistryLocalBridgeRow, and InspectCommandActionBlock.
4. Polish primitives: ScoreEmblemView, icon loaders, CopyIconButton, color tokens, dividers, and command preview sizing.
5. Validate static render with fixture snapshot and compare to the persisted final-polish mockup.
6. Validate build, bundle, tests, and live MenuBarExtra behavior through repo-native commands.

## Validation Gates

- Command: HOME=/private/tmp/skillsbar-home XDG_CACHE_HOME=/private/tmp/skillsbar-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build -> pass|fail|blocked (...)
- Command: NO_OPEN=1 ./Launch.command -> pass|fail|blocked (...)
- Command: HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build -> pass|fail|blocked (...)
- Command: SKILLSBAR_REVIEW_FIXTURE=1 TESSL_REGISTRY_FIXTURE=1 TESSL_REGISTRY_FIXTURE_SCORE=66 TESSL_REGISTRY_FIXTURE_VERSION=0.2.0 TESSL_REGISTRY_FIXTURE_QUALITY=100 TESSL_REGISTRY_FIXTURE_IMPACT=63 TESSL_REGISTRY_FIXTURE_SECURITY=Passed TESSL_REGISTRY_FIXTURE_EVALS=68 <built SkillsBar executable> --snapshot <path> -> pass|fail|blocked (...)
- Command: script/build_and_run.sh --verify -> pass|fail|blocked (...)

Manual/runtime evidence required before implementation closeout: current menubar screenshot, clipboard proof for the full inspect command, keyboard focus traversal, reduced-motion behavior classification, and height fit statement.

## Acceptance Mapping

- SA-001: ReviewHeaderView plus fixture local score/security.
- SA-002: LocalReviewTriggerCard with no accordion state.
- SA-003: metric columns fed by MetricSignal and SecuritySignal.
- SA-004: RegistryComparisonRow fed by TesslSignal.
- SA-005: RegistryLocalBridgeRow.
- SA-006: InspectCommandActionBlock graphite/neutral styling.
- SA-007: CopyFeedbackModel.copy invoked with model command string.
- SA-008: focus/accessibility pass on details and copy controls.
- SA-009: no custom transform-heavy motion, or reduced-motion alternate if custom motion exists.
- SA-010: MenuBarTemplateMetrics plus live height check.
- SA-011: mixed bridge glyph.
- SA-012: header and amber hierarchy tuned in live screenshot.

## Recommendations For Coordinator Merge

Take this architecture as the low-risk spine for the refactor unless the adversarial review finds a blocking command/data contract issue. The one product-level blocker is still the canonical inspect command: the UI can be built around security.inspectCommand today, but the final command label/copy expectation should be confirmed against the local SDK command contract before claiming SA-007.

## Evidence Commands Run By This Review

- Command: sed -n '1,260p' <requested source files> -> pass (read requested source surfaces; longer files required follow-up line-number reads)
- Command: nl -ba Sources/SkillsBar/Views/DashboardView.swift | sed -n '1,420p' -> pass (read current popover composition and first component set with line numbers)
- Command: nl -ba Sources/SkillsBar/Views/DashboardView.swift | sed -n '421,900p' -> pass (read local checks, identity, security, Tessl, and action components with line numbers)
- Command: nl -ba Sources/SkillsBar/Views/DashboardView.swift | sed -n '881,1175p' -> pass (read logo loaders, copy button, primitives, and color tokens with line numbers)
- Command: nl -ba Sources/SkillsBar/Models/DashboardModels.swift | sed -n '1,760p' -> pass (read dashboard/security/Tessl model display surfaces with line numbers)
- Command: nl -ba Sources/SkillsBar/Services/DashboardLoader.swift | sed -n '1,760p' -> pass (read loader commands, fixture support, and security parsing with line numbers)
- Command: nl -ba Sources/SkillsBar/Support/Snapshot.swift | sed -n '1,140p' -> pass (read snapshot renderer proof lane)
- Command: product build or runtime validation -> blocked (architecture review only; no code implementation was performed by this subagent)

## Artifact Accountability

artifact_path: .harness/reviews/2026-07-09-review-popover-architecture-review.md
manifest_path: artifacts/agent-runs/default-019f481c-25b2-7822-b99c-951923d5bfa5/manifest.json
mandatory_mirror: artifacts/reviews/default.md
