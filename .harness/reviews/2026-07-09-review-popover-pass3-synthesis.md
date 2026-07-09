# Pass-Three Review Synthesis: Review Popover Spec

schema_version: 1
date: 2026-07-09
target: SkillsBar macOS MenuBarExtra(.window) review popover
spec_path: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md

## Bottom Line

Pass three found and folded in the remaining spec/doc handoff defects from the adversarial lane: the details control is now conditional, command naming uses `reviewInspectCommand`, and the synthesis validation route uses the exact V-011 snapshot command instead of a placeholder.

After those updates, the agent-native lane found no further spec/doc handoff defects. The architecture lane found no remaining MenuBarExtra-versus-normal-window conflict, but did identify one implementation blocker: the current snapshot path still calls the live dashboard loader and must gain the deterministic `SKILLSBAR_REVIEW_FIXTURE=1` seam before final-polish snapshot proof can pass.

## Pass-Three Artifacts

- .harness/reviews/2026-07-09-review-popover-adversarial-pass3.md
- .harness/reviews/2026-07-09-review-popover-agent-native-pass3.md
- .harness/reviews/2026-07-09-review-popover-architecture-pass3.md

## Folded-In Spec/Doc Fixes

- Details interface row is conditional: if no destination is confirmed, omit the control or render it disabled with an accessible reason.
- Data/domain and interface naming consistently use `reviewInspectCommand`.
- README routes implementers to the three-lane synthesis.
- The three-lane synthesis validation route uses the exact deterministic snapshot command from V-011 and marks it blocked until the fixture and command contract exist.

## Remaining Implementation Blockers

- Confirm the canonical `reviewInspectCommand` string.
- Implement the deterministic `SKILLSBAR_REVIEW_FIXTURE=1` model seam before `SnapshotRenderer` enters live package, scenario, registry, or security parsing.
- Bind the fixture command, visible preview, accessibility value, copy action, and pasteboard validation to `reviewInspectCommand`.
- Confirm the details destination or omit/disable the details control.
- Choose final MenuBarExtra point metrics and icon variants.
- Produce fresh live MenuBarExtra proof for screenshot comparison, clipboard equality, keyboard focus traversal, reduced-motion classification, and height fit.

## Coordinator Verdict

No further spec/doc handoff defects are known after pass three. The remaining issues are implementation blockers for the refactor itself, not unresolved contradictions in the current spec.
