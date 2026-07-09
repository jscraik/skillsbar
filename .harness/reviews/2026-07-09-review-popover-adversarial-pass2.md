# SkillsBar Review Popover Adversarial Pass 2

schema_version: 1
review_type: adversarial_spec_review
target_spec: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
target_surface: macOS MenuBarExtra(.window) review popover
status: issues_found_and_remediated
review_date: 2026-07-09

## Bottom Line

The first three-lane review findings were implemented into the spec: the spec now preserves the macOS MenuBarExtra(.window) shell, points to the final-polish mockup, adds copy-only command semantics, requires deterministic final-polish fixture proof, and expands acceptance through SA-015. Pass 2 found two remaining spec-level conflicts. Both were remediated in the spec during this pass. No further spec/doc contradictions were found after the remediation and shape validators passed.

## Fold-In Verification

- MenuBarExtra boundary present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:110 and :159.
- Copy-only review action present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:143 and :329.
- Deterministic final-polish fixture present: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:144, :312, and :330.
- Final-polish mockup is the visual target: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:89, :122, and :337.
- README routes to final-polish artifact: README.md:103.
- Current implementation evidence confirms this is a MenuBarExtra(.window): Sources/SkillsBar/App/SkillsBarApp.swift:16-24.

## Findings Remediated In Pass 2

### P1. Motion language overrode native MenuBarExtra ownership

Evidence:
- Prior spec language required popover opening/closing motion to originate from the menubar trigger with a custom spring.
- Current app uses native MenuBarExtra(.window), evidenced by Sources/SkillsBar/App/SkillsBarApp.swift:16-24.
- User correction: "Its a macOS menubar."

Risk:
A future implementer could fight AppKit by adding a custom popover presentation layer or transform stack around the native menu-bar window, creating a non-native feel and implementation risk.

Remediation applied:
- NFR-008 now says the popover must preserve native MenuBarExtra(.window) anchoring and only applies spring guidance to custom interior transitions.
- NFR-009 now requires reduced-motion handling only for custom transform-heavy interior motion, or explicit closeout that no custom transform-heavy motion was added.
- Interface and implementation notes now use native presentation as the baseline.

Post-remediation evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:155-156.
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:169.
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:367-368.

### P2. Open questions duplicated command and size blockers

Evidence:
- Prior Open Questions had both "What is the exact canonical inspect command?" and "Should the canonical copy command be the current JSON/robot risk-modes command or a shorter human-facing inspect command?"
- Prior Open Questions had both "What exact laptop viewport/window height..." and "What target point size..."

Risk:
Duplicated blockers can cause planning churn or false disagreement over whether a blocker is one decision or two.

Remediation applied:
- Merged command question into one explicit choice.
- Merged viewport/point-size question into one acceptance-target question.

Post-remediation evidence:
- .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md:377-380.

## Remaining Open Items

These are intentional implementation inputs, not spec contradictions:

- Canonical inspect command must be confirmed before implementation closeout.
- Details icon destination must be selected.
- Target laptop viewport/window height and MenuBarExtra point size must be selected.
- Icon asset variant availability must be confirmed or implementation must create/export optical variants.
- Runtime proof remains blocked until live app validation exists: screenshot comparison, clipboard equality, keyboard focus, reduced motion, and height fit.

## No Further Issues Found

After remediation, I did not find remaining spec/doc conflicts in the reviewed scope. The current implementation still does not match the final-polish spec, but that is the known implementation work, not a spec defect. The implementation handoff remains coherent: replace the current dashboard/comparison body while preserving MenuBarExtra(.window).

## Validation Evidence

Command: `python3 /Users/jamiecraik/.codex/plugins/cache/agent-skills-local/harness-engineering/0.1.0/scripts/check_bluf_structure.py .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md --json` -> pass (exit 0)

Command: `python3 /Users/jamiecraik/.codex/plugins/cache/agent-skills-local/harness-engineering/0.1.0/scripts/check_generated_artifact_shape.py .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md --kind spec --json` -> pass (exit 0)

Command: `rg -n "Should the canonical copy command|What target point size|opening/closing motion SHOULD|Opens from the menubar item origin" .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md` -> pass (exit 1; stale conflicting phrases absent)

Command: `live MenuBarExtra runtime validation` -> blocked (spec/doc review only; no live menu-bar popover screenshot, clipboard equality, focus traversal, reduced-motion mode, or height measurement was performed)

WROTE: .harness/reviews/2026-07-09-review-popover-adversarial-pass2.md
