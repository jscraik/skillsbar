# Adversarial Pass 3: Review Popover Spec/Docs

schema_version: 1
date: 2026-07-09
target: SkillsBar macOS MenuBarExtra(.window) review popover
reviewed_paths:
  - .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
  - README.md
  - .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md
  - Sources/SkillsBar/App/SkillsBarApp.swift
  - Sources/SkillsBar/App/MenuBarTemplateMetrics.swift
  - Sources/SkillsBar/Support/Snapshot.swift

## Verdict

No further spec/doc errors, contradictions, false readiness claims, or MenuBarExtra-vs-window conflicts were found in this pass.

The pass-2 and pass-3 findings have been incorporated into the spec/doc layer: the spec now preserves the macOS MenuBarExtra(.window) boundary, requires a single `reviewInspectCommand` source, adds deterministic final-polish fixture mapping, blocks the snapshot command until fixture/command contracts exist, truthfully handles unresolved details behavior, and keeps runtime proof separate from generated mockup proof.

## Evidence Reviewed

- MenuBarExtra shell remains current implementation truth: `SkillsBarApp.swift:15-24` uses `MenuBarExtra` with `.menuBarExtraStyle(.window)`.
- Current fixed point metrics remain documented as an implementation constraint, not a claimed final fit: `MenuBarTemplateMetrics.swift:3-5`.
- SnapshotRenderer still loads live dashboard data before rendering: `Snapshot.swift:19-23`; the spec and synthesis now correctly require a fixture seam before final-polish snapshot proof.
- README routes implementers to the spec, final-polish mockup, and three-lane synthesis.
- The synthesis explicitly says the app shell is correct and the refactor risk is inside the popover body, command model, fixture proof, and runtime validation.

## Findings

None.

## Intentional Implementation Blockers Still Present

These are not spec/doc contradictions; they are intentionally unresolved implementation inputs or proof gates:

- Canonical `reviewInspectCommand` string is still unresolved.
- Top-right details destination is still unresolved; spec correctly requires omit/disabled behavior until confirmed.
- Target laptop viewport/MenuBarExtra point size still needs acceptance input and live proof.
- Skills SDK icon optical variants still need confirmation/export.
- Current SwiftUI implementation still renders the older DashboardView stack; the synthesis correctly identifies this as the next refactor target.
- Final-polish fixture support and SnapshotRenderer fixture routing are not implemented yet; the spec correctly blocks V-009/V-011 until they exist.
- Clipboard equality, focus traversal, reduced-motion behavior, and live height proof remain blocked until product code is refactored and launched.

## Validation Evidence

Command: `python3 /Users/jamiecraik/.codex/plugins/cache/agent-skills-local/harness-engineering/0.1.0/scripts/check_bluf_structure.py .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md --json` -> pass (validator returned status pass)

Command: `python3 /Users/jamiecraik/.codex/plugins/cache/agent-skills-local/harness-engineering/0.1.0/scripts/check_generated_artifact_shape.py .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md --kind spec --json` -> pass (validator returned status pass)

Command: `test -f .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png` -> pass (visual target exists)

Command: `test -f .harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.prompt.md` -> pass (prompt sidecar exists)

Command: `test -s .harness/reviews/2026-07-09-review-popover-3lane-synthesis.md` -> pass (synthesis artifact exists and is non-empty)

## Closeout

No further adversarial edits are recommended at the spec/doc layer before implementation planning. The next useful review should happen after the SwiftUI refactor introduces `reviewInspectCommand`, final-polish fixture support, the review-state component stack, and live proof artifacts.
