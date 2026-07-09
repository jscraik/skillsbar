# Architecture Pass 3: Review Popover

schema_version: 1
date: 2026-07-09
target: SkillsBar macOS MenuBarExtra(.window) review popover
scope: architecture/spec conflict review only

## Bottom Line

No P0 normal-window architecture conflict remains. The app shell is still a macOS `MenuBarExtra` rendered with `.menuBarExtraStyle(.window)`, matching the spec boundary that forbids replacing this slice with `WindowGroup`, `NavigationSplitView`, sidebar/detail, document-window, or standalone-window architecture.

One P1 proof-architecture conflict remains: snapshot rendering still enters the live dashboard loader directly, while the spec requires a deterministic final-polish review fixture seam before live command parsing when `SKILLSBAR_REVIEW_FIXTURE=1` is set.

## Findings

### P1. Snapshot path lacks the required final-polish fixture seam

The spec requires deterministic final-polish fixture support for screenshot/snapshot proof and explicitly says `SnapshotRenderer` must route through that fixture seam before live command parsing when `SKILLSBAR_REVIEW_FIXTURE=1` is set. The current snapshot path constructs `DashboardLoader().loadSync()` directly, then renders `DashboardView` at the shared menubar metrics. That means the snapshot proof lane still depends on live/local parsing rather than the required final-polish fixture model.

Evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:397
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:399
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:413
- Sources/SkillsBar/Support/Snapshot.swift:19
- Sources/SkillsBar/Support/Snapshot.swift:21
- .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:132

Remediation:
- Add a deterministic review fixture entrypoint such as `SKILLSBAR_REVIEW_FIXTURE=1`.
- Route `SnapshotRenderer` through that fixture before `DashboardLoader().loadSync()` or make the loader itself select the fixture before live package/scenario/registry/security command parsing.
- Bind the fixture's action command to the same future `reviewInspectCommand` presentation field used by visible preview, accessibility value, copy action, and pasteboard validation.

## Confirmed Non-Conflicts

- The scene architecture is compliant: `SkillsBarApp` declares `MenuBarExtra`, renders `DashboardView` in that menu-bar scene, and applies `.menuBarExtraStyle(.window)`.
  Evidence: Sources/SkillsBar/App/SkillsBarApp.swift:15, Sources/SkillsBar/App/SkillsBarApp.swift:16, Sources/SkillsBar/App/SkillsBarApp.swift:24.
- The spec and synthesis agree that normal app-window architecture is out of scope for this slice.
  Evidence: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:110, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:396, .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:75.
- README routing now describes the app as a compact SwiftUI menu-bar popover and preserves proof-lane separation.
  Evidence: README.md:3, README.md:15, README.md:109.

## Intentional Implementation Blockers

- Canonical inspect command remains unresolved; the spec treats the mockup command as a placeholder.
  Evidence: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:390, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:406.
- Details destination remains unresolved; any details control must be omitted, disabled with an accessible reason, or wired only to a confirmed destination.
  Evidence: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:400, .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:407.
- Target laptop viewport/window height and final MenuBarExtra point size remain unresolved. Current shared metrics are still 356 x 560 points, and synthesis correctly treats the bitmap mockup as a visual target rather than literal point dimensions.
  Evidence: Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:3, Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:4, Sources/SkillsBar/App/MenuBarTemplateMetrics.swift:5, .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:61.
- Live proof is still required before implementation closeout: screenshot, clipboard equality, keyboard focus traversal, reduced-motion classification, and height-fit evidence.
  Evidence: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:253, README.md:126, .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md:136.

## Status

Architecture pass complete. No further MenuBarExtra-versus-normal-window conflict found. The remaining architecture/spec issue is the deterministic fixture/snapshot proof path.

WROTE: .harness/reviews/2026-07-09-review-popover-architecture-pass3.md
