---
schema_version: 1
artifact_id: spec-2026-07-10-skillsbar-pipeline-posture
artifact_type: implementation-spec
canonical_slug: skillsbar-pipeline-posture
title: SkillsBar Pipeline Posture Default Implementation Spec
status: approved_documentation_contract
date: 2026-07-10
origin: user-approved pipeline posture mockup
risk: medium
ui_spec: true
traceability_required: true
human_acceptance_boundary: satisfied_for_documentation_contract
runtime_state: not_implemented
visual_reference: .harness/media/2026-07-10-skillsbar-pipeline-posture-approved.png
supersedes: .harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md
---

# SkillsBar Pipeline Posture

## Command Summary

Make the selected pipeline-posture mockup the default SkillsBar experience.
The app shows a local Skill SDK candidate progressing through sequential,
evidence-backed stages. It must make the active blocker, its contribution to
the current local posture, and the next inspection action obvious. Tessl remains
a visually recognisable, historical external baseline with its own product
language. It does not certify the changed local candidate.

The retained visual reference is:

![Approved SkillsBar pipeline posture mockup](../media/2026-07-10-skillsbar-pipeline-posture-approved.png)

This image guides hierarchy, custom icons, score display, density, and color
semantics. The requirements below are authoritative when the image and prose
differ.

## Product Contract

### Primary Job

Help a Skill SDK maintainer answer, in one glance:

1. What stage is the current local candidate in?
2. What evidence is current for that candidate?
3. What specific finding must be improved before progress can continue?
4. How does the last Tessl baseline compare without being mistaken for proof?

SkillsBar is a visual guide for local SDK work. It is not a publication control,
an automatic repair agent, or an authorization engine.

### Evidence Boundaries

- A current local candidate is identified by a fingerprint over governed inputs:
  `SKILL.md`, core references, package identity, scenario set, criteria, rubric,
  scorer, and declared model profile.
- Any governed-input change supersedes active proof for that candidate. The
  display returns to the first stage and shows later proof as unproven until it
  is re-established for the new fingerprint.
- Prior Tessl data remains a dated historical baseline. It is never added to the
  local candidate posture and must be labelled as not proof for the candidate.
- Local package shape, security, `oss-local`, `oss-cloud`, Tessl staging, live
  Tessl scoring, and runtime observation remain distinct evidence lanes.
- A later lane cannot mask an earlier unproven or failed lane.

## Six-Stage Presentation

The app groups the canonical SDK lifecycle into six scan-friendly stages without
flattening the evidence within them.

| Order | Visible stage | SDK evidence represented | Weight |
| --- | --- | --- | ---: |
| 1 | Candidate baseline | candidate fingerprint, SDK entry, package shape and mechanical validation | 15 |
| 2 | Security review | `oss-security` guardrail findings and remediation | 25 |
| 3 | Local eval proof | current fixed scenario set under the `oss-local` sandbox profile | 20 |
| 4 | Cloud eval proof | the same scenario identities under the independent `oss-cloud` profile | 20 |
| 5 | Tessl staging | Tessl local proof, scenario-source gate, version alignment, and live-private dry run | 10 |
| 6 | Live score and runtime | preserved Tessl live view/score feedback plus installed runtime observation | 10 |

The ordered stages are strict. Security is resolved before Local eval proof
(`oss-local`); a failed
or blocked stage holds later stages as **Unproven**, rather than showing them as
failed or silently reusing stale evidence.

## Pipeline Posture Score

The header hex is the **current local candidate pipeline posture** on a 0-100
scale. It is not the old Q/I/S arithmetic and it is not the Tessl registry score.

For a current candidate fingerprint:

```text
pipeline posture = sum(round(stage_weight * stage_score / 100))
```

- A verified stage supplies its evidence-derived `stage_score` from 0 to 100.
- An unproven stage contributes `0` and is visibly labelled **Unproven**; this
  means no current evidence exists, not that the underlying work is known bad.
- A stale receipt contributes `0` after a governed-input change.
- A failed early hard gate caps the displayed posture below any release-like
  threshold and makes the active failure the primary state.
- The header also states the count of stages with current evidence, for example
  `2 of 6 stages evidenced`.

The approved mockup is an illustrative state:

```text
Candidate baseline: 100 x 15% = 15
Security review:    35 x 25% =  9 (rounded from 8.75)
Other four stages:  unproven =  0
Pipeline posture:                  24
```

Every visible contribution must reconcile with the header hex. The UI must not
show a number whose stage arithmetic cannot explain it.

## Visual Requirements

### Header

- Show the custom Skills SDK document icon from `SkillsSDKIcon.png` in the
  header source treatment. Do not replace it with a generic document glyph.
- Use `Candidate requires review` for an active review state.
- Show the selected package and a small `LOCAL` source label.
- Show the pipeline posture in a Tessl-style amber outlined hex with the labels
  `pipeline posture` and `<n> of 6 stages evidenced`.
- The hex must be visually tied to the local candidate. It must not use Tessl
  wording or imply that an external score has been earned.

### Pipeline

- Present the six stages in order with a stable contribution column.
- Use a green check only for a current passed stage.
- Give the active blocked or review stage a restrained amber leading indicator,
  its score, contribution, concrete blocker copy, and one icon-only copy action
  for the inspection command.
- Use muted lock/clock semantics for later unproven stages. They must not look
  red or failed.
- Show the score and contribution for evidenced stages, then `Unproven` and an
  em dash for unreached stages.
- State: `Unproven stages contribute 0; stale results never carry forward.`
- Do not introduce generic feature-tour copy, hidden remediation, or automatic
  terminal execution.

### Tessl Historical Baseline

- Use the custom Tessl cube asset from `TesslLogo.png`. Do not replace it with
  a generic package or box symbol.
- Label the panel `Tessl Registry` and render the package/version from the
  external registry data.
- Preserve Tessl's recognizable score language inside the secondary panel:
  amber outlined hex score, green Quality and Security indicators, amber Impact
  indicator, and a green `1.28x` lift badge when the registry provides it.
- A restrained teal/cyan perimeter and text accent identify the Tessl source;
  teal is not a local pass color.
- Render: `Historical registry baseline - not proof for current local candidate.`
- The registry card is secondary to the local active stage. Its score and
  metrics never contribute to the local posture hex.

### Action

- Place one compact next-action surface after the evidence cards.
- The action is owned by the active stage. For security review, show the risk
  summary and copy the full canonical `risk-modes` inspect command.
- The copy control is icon-only, has a clear tooltip and accessible name, and
  copies the full command even when the preview is visually shortened.
- Keep the terminal glyph, action text, and command preview calm and neutral;
  do not style this action as an amber warning panel.

### Apple-Design Constraints

- Retain the native `MenuBarExtra(.window)` shell and its anchored relationship
  to the menu bar.
- Use restrained graphite material, a fine boundary, system typography, and
  stable row geometry. Do not add a normal application window, dashboard
  navigation, decorative gradients, or speculative motion.
- Treat motion as optional and native-led. If custom motion is added, use a
  critically damped, non-bouncy transition and use an opacity/material
  alternative for reduced-motion users.
- The active-stage action receives immediate pointer and keyboard feedback;
  accessibility focus is visible and not amber.

## Data Contract

The next implementation must add an explicit model rather than infer stages
from the existing independent snapshot fields.

```text
PipelineCandidate
  fingerprint
  governedInputPaths
  observedAt
  stageReceipts[]
  postureScore
  evidencedStageCount

PipelineStageReceipt
  stage
  candidateFingerprint
  evidenceStatus: passed | review_required | blocked | unproven | stale
  stageScore: 0...100 | null
  contribution: 0...weight
  command
  receiptPath
  modelProfile
  observedAt
  nextAction

HistoricalTesslBaseline
  version
  score
  quality
  impact
  security
  lift
  runOrRegistryReference
  observedAt
  provenance: historical_external
```

The implementation must not fabricate `oss-local`, `oss-cloud`, Tessl staging,
or live-score receipts from the existing `scenario-quality` preview result.
Missing evidence remains unproven.

## Acceptance Criteria

- AC-001: A local candidate fingerprint is visible in the model and invalidates
  active stage receipts when a governed input changes.
- AC-002: The six stage weights are exactly `15, 25, 20, 20, 10, 10` and the
  header hex equals the sum of visible stage contributions.
- AC-003: Security review precedes `oss-local`; later stages remain Unproven
  until the earlier stage has current passing evidence.
- AC-004: The custom Skills SDK and Tessl icons are used in their source rows.
- AC-005: The Tessl card preserves its score, Quality, Impact, Security, and
  lift language, while carrying the historical-not-proof disclaimer.
- AC-006: Tessl historical data does not change the local candidate posture.
- AC-007: The active stage exposes a single evidence-backed copy action whose
  visual preview and pasteboard value use the same command source.
- AC-008: The app renders a deterministic pipeline-posture fixture matching the
  approved visual hierarchy without claiming it is a live MenuBarExtra proof.
- AC-009: Accessibility, reduced-transparency, increased-contrast, and small
  visible-frame behavior are checked against the implemented surface.

## Implementation Boundary

This approved specification authorizes a later bounded SwiftUI Worker slice. It
does not authorize the Project PM to implement the app itself. Before code
changes, the PM must create a Worker packet naming exact source files and
validators plus an independent QA Disproof packet that inspects the actual
output.

## Proof Boundary

This document and the retained mockup prove only the selected design contract.
They do not prove SwiftUI implementation, unit tests, live macOS menu-bar
rendering, clipboard behavior, accessibility behavior, Tessl authentication,
registry freshness, publication, or release readiness.
