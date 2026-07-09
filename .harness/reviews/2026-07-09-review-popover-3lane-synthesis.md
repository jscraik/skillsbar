# Three-Lane Review Synthesis: Review Popover Refactor

schema_version: 1
date: 2026-07-09
target: SkillsBar macOS MenuBarExtra review popover
spec_path: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
visual_target: .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png
review_artifacts:
  - .harness/reviews/2026-07-09-review-popover-adversarial-review.md
  - .harness/reviews/2026-07-09-review-popover-agent-native-review.md
  - .harness/reviews/2026-07-09-review-popover-architecture-review.md

## Bottom Line

The three-lane review agrees that SkillsBar should remain a macOS MenuBarExtra(.window) app and that the refactor should replace the current dashboard/comparison interior with the final-polish review-popover narrative. The app shell is the right architecture; the risk is inside the popover body, command model, deterministic fixture proof, and runtime validation. The next implementation slice should not create a normal app window, NavigationSplitView, or document-style scene.

## Consensus Findings

### P0. Refactor the rendered popover structure, not just styling

Current DashboardView renders an older dashboard stack: header, skill identity, proof-lane comparison table, fleet summary, local checks, security block, and command dock. The final-polish spec requires a narrative stack: header, package identity, expanded local review trigger, secondary registry row, mixed registry/local bridge, and one neutral copy action.

Evidence:
- Sources/SkillsBar/Views/DashboardView.swift:12-24
- Sources/SkillsBar/Views/DashboardView.swift:183-229
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:123-138

Next move:
- Introduce a review-state component stack inside DashboardView or a dedicated ReviewPopoverView.
- Stop rendering ProofLaneComparisonView, FleetSummaryView, SecurityBlock, TesslBlock, PrimaryAction, InstallCommand, and FooterBar in the final review state unless a later mode explicitly needs them.

### P0. Resolve canonical copy-command semantics before claiming SA-007

The spec says the action is Copy inspect command, while current CommandDock can copy dashboard.security.inspectCommand, open the Tessl registry, launch Terminal, or copy recovery commands depending on state. The implementation needs one named command source for the review-state action.

Evidence:
- Sources/SkillsBar/Views/DashboardView.swift:715-813
- Sources/SkillsBar/Models/DashboardModels.swift:84-86
- Sources/SkillsBar/Services/DashboardLoader.swift:413-444
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:133-136

Next move:
- Add the named reviewInspectCommand presentation property.
- Decide whether the copied command is the existing JSON/robot risk-modes command or a shorter human-facing inspect command.
- Test pasteboard output against that model property, not against rendered text.

### P1. Add deterministic fixture support for the final-polish state

The generated target depends on specific values: score 78, quality 100%, impact 71/71, security 3 risks, registry score 66, registry quality 100%, registry impact 63%, registry security Passed, and 68 registry eval scenarios. Tessl fixture support exists, but local fixture support does not.

Evidence:
- Sources/SkillsBar/Services/DashboardLoader.swift:339-360
- Sources/SkillsBar/Services/DashboardLoader.swift:413-477
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:166-176

Next move:
- Add SKILLSBAR_REVIEW_FIXTURE=1 or equivalent.
- Use it for snapshot and visual comparison proof only.
- Keep live data parsing intact and separate from the fixture lane.

### P1. Treat the mockup as a visual target, not literal point dimensions

The final image is 975 x 1614 pixels; the current MenuBarExtra frame is 356 x 560 points. The refactor needs a realistic menu-bar popover size and height-fit proof, not blind pixel matching.

Evidence:
- Sources/SkillsBar/App/SkillsBarApp.swift:16-24
- Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:3-5
- .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png

Next move:
- Set named popover metrics and command-preview height.
- Validate snapshot and live MenuBarExtra height on the target display.
- If height is tight, compress spacing before removing required status, local trigger, bridge, or action content.

### P1. Preserve MenuBarExtra(.window) and avoid normal-window architecture

The user corrected that this is a macOS menubar app. The reviewers agree the shell is already correct. The refactor should not introduce WindowGroup, NavigationSplitView, sidebar/detail structure, or a document-style window.

Evidence:
- Sources/SkillsBar/App/SkillsBarApp.swift:15-24
- README.md:1-14
- AGENTS.md:26-42

Next move:
- Keep SkillsBarApp scene unchanged unless metrics or snapshot wiring requires a small adjustment.
- Keep build/run proof through Launch.command and script/build_and_run.sh.

### P1. Add focus, pointer feedback, and reduced-motion proof routes

Plain icon buttons currently have accessibility labels, but visible focus and pointer-down feedback are not proven. The spec requires focus traversal and reduced-motion behavior in the menu-bar popover context.

Evidence:
- Sources/SkillsBar/Views/DashboardView.swift:1065-1088
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:149-152
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:303-314

Next move:
- Add explicit focus styling or platform-visible focus treatment for details/copy controls.
- Add press feedback that does not resize layout.
- If no custom open animation is added, document that native MenuBarExtra owns popover materialization and verify no unguarded transform-heavy motion exists.

### P2. Keep agent-facing routing docs on the final-polish artifact

README now points at the final-polish mockup and three-lane synthesis, while retaining the older mockup as historical comparison evidence. Future implementation agents should treat the final-polish media path as the current target.

Evidence:
- README.md:82-104
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:317-329

Next move:
- Keep README, this synthesis, and the spec aligned if the current visual target changes again.

## Proposed Component Boundary

- ReviewPopoverView: final vertical sequence for MenuBarExtra content.
- ReviewHeaderView: header icon, Skills SDK label, Needs review, substatus, details button, restrained score hex.
- PackageIdentityBlock: repo path, Private pill, package subtitle.
- LocalReviewTriggerCard: warning rail, source row, metric row, three columns.
- RegistryComparisonRow: Tessl icon, registry package, version/score, quiet metric summary.
- RegistryLocalBridgeRow: green check plus amber local-finding dot and bridge copy.
- InspectCommandActionBlock: neutral command-copy surface with stable two-line preview.
- CopyIconButton: reusable button with stable hit target, focus styling, press feedback, and pasteboard binding.

## Validation Route

Command: `HOME=/private/tmp/skillsbar-home XDG_CACHE_HOME=/private/tmp/skillsbar-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build` -> required after code changes

Command: `NO_OPEN=1 ./Launch.command` -> required after bundle/resource changes

Command: `HOME=/private/tmp/skillsbar-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build` -> required after model/loader/copy behavior changes

Command: `SKILLSBAR_REVIEW_FIXTURE=1 TESSL_REGISTRY_FIXTURE=1 TESSL_REGISTRY_FIXTURE_SCORE=66 TESSL_REGISTRY_FIXTURE_VERSION=0.2.0 TESSL_REGISTRY_FIXTURE_QUALITY=100 TESSL_REGISTRY_FIXTURE_IMPACT=63 TESSL_REGISTRY_FIXTURE_SECURITY=Passed TESSL_REGISTRY_FIXTURE_EVALS=68 swift run --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-snapshot-build SkillsBar --snapshot /private/tmp/skillsbar-final-polish.png` -> blocked until fixture and command contract exist

Command: `script/build_and_run.sh --verify` -> required for live MenuBarExtra process proof when appropriate

Manual/runtime proof still required:
- live menu-bar screenshot
- pasteboard equality for the inspect command
- keyboard focus traversal
- reduced-motion classification
- height-fit statement

## Review Artifact Status

Command: `test -s .harness/reviews/2026-07-09-review-popover-adversarial-review.md` -> pass (reported by adversarial reviewer)
Command: `test -s .harness/reviews/2026-07-09-review-popover-agent-native-review.md` -> pass (reported by agent-native reviewer)
Command: `test -s .harness/reviews/2026-07-09-review-popover-architecture-review.md` -> pass (reported by architecture reviewer)
