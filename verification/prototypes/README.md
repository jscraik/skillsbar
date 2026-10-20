# Complete menu comparison

For the current saved prototype and restart instructions, see [REOPEN.md](REOPEN.md).
That file describes the latest gate overview/detail navigation and search.
The notes below retain earlier design iterations and their historical checks.

## Tessl reference revision

The user's two score-section screenshots now drive a compact stacked assessment:
one overall hexagon and multiplier, quality with explanatory text, impact with
a baseline track and scenario count when recorded, and five security segments.
The observed Simplify snapshot retains 97 / 94% / 98% / 0.98× and does not invent
a scenario count, Snyk attribution, or scan-findings detail. Reference fixtures
demonstrate 97 / 97% / 99% / 1.25× across three scenarios and 47 / 59% with
missing evals. Snyk attribution belongs only to those supplied examples.

There is one persistent branded tile, with Registry typeset inside the tile
below the supplied wordmark. The duplicate image and Registry heading in the
scrolling detail were removed. The score results appear once. The missing-eval
fixture offers a preview guide and copy-only Tessl review-fix command; neither
executes checks or mutates skills.

Command: `node --check verification/prototypes/prototype.js` -> pass.
Command: `git diff --check` -> pass.
Safari accessibility readback confirmed the single Tessl Registry image,
retained observed metrics, baseline explanation, segmented-security label and
new assessment selector. Subsequent scrolling/screenshot capture returned
`noWindowsAvailable`; the reference fixtures and guide did not receive a
complete visual/interaction acceptance pass in that browser session.
SkillsBar's layout-source hash remains unchanged.

Open `http://127.0.0.1:8769/simplify-evidence.html`. Serve this directory with
`python3 -m http.server 8769 --bind 127.0.0.1 --directory verification/prototypes`
from the SkillsBar repository if the local server is no longer running.
These are browser prototypes. They are not imported by the macOS app.

The supplied Tessl wordmark is retained as `tessl-wordmark.png`, without
cropping or changing its pixels. Both the persistent identity strip and full
registry card use it at its original aspect ratio. Adjacent headings say
Registry to avoid repeating the Tessl name already present in the image.
The asset update passed JavaScript syntax and diff checks. Its final browser
visual check was interrupted by concurrent Chrome use; reload the preview
to load the new asset. The earlier scrolling/visibility proof used the
previous Tessl icon, with the same fixed-strip placement.

## Comparison contract

1. Menu parity: actual menu labels, stage details and utility controls, plus
   the shared persistent Tessl identity strip.
2. Evidence clarity: shorter evidence text, explicitly scoped registry
   security and baseline wording. Same controls and geometry.
3. Guided evidence: adds expandable provenance context and next-step guidance.

All variants use a 460 × 586 CSS-pixel frame, with a 450-pixel short-display
condition. This approximates the native point dimensions; it is not a claim
of pixel-identical SwiftUI materials or native menu rendering. The shared
Tessl strip remains outside the scrollable content and above open browser
menus. The full registry card remains available in the scroll area.

The comparison picker supports keys 1–3, persists the variant in `?v=`, and
switches the content immediately. Arrow keys within the gate grid move between
gates instead of switching variants. Escape dismisses a menu first, otherwise
closes the preview. Reopen restores it. Quit never terminates SkillsBar.

## Complete control inventory

- Header icon, name, local/demo origin, version and overall state.
- Nine numbered gates with distinct evidence states, selected/next-required
  styling and keyboard focus; summary counts and selected-stage details.
- Expandable, selectable command and clipboard success/failure feedback.
  The inspected standalone Simplify route uses a comparison fallback for
  downstream gates; improved variants explicitly identify that limitation.
- More menu: grouped Select skill, selected marker, environment pinning,
  Copy summary, Copy latest observation, Copy selected skill path,
  Copy model profile, Quit SkillsBar and Close popover.
- Tessl logo, source availability, version, observation age, package path,
  registry score, multiplier, quality, impact, security, evidence boundary,
  and external Tessl registry link.
- Checked-time footer, refreshing, failure with retained prior observation,
  and successful simulated refresh.

The chooser snapshot contains 497 entries across 63 groups on 20 October 2026.
`capture_inventory.py` reads names and paths, not skill bodies into the fixture;
it writes only `inventory.js`. It does not install or modify skills. Selecting
another skill produces a clearly marked fixture with unlinked registry state,
so Simplify's registry figures cannot be attributed to it. Runtime fixtures
are deliberately separate from actual SDK results.

## Verification on 20 October 2026

- Command: `python3 verification/prototypes/capture_inventory.py` -> pass
  (63 groups, 497 entries).
- Command: `node --check verification/prototypes/prototype.js` -> pass.
- Command: `git diff --check` -> pass.
- Browser: all three variants rendered; variant selection persisted in URL.
- Browser: all nine stages selected; Identity remained next required while
  inspecting other stages. Neutral focus and blue/amber selection are modelled.
- Browser: all chooser origin groups and SkillsBar Internal 0.1.2 were present;
  pin disabled selection; unpin allowed selecting its verification skill.
- Browser: each of the four utility copy actions confirmed clipboard success.
  Copy failure showed Retry copy; the final implementation retains failure
  feedback until another copy outcome.
- Browser: Escape dismissed the open menu. Quit closed only the preview,
  and Reopen restored it.
- Browser: Guided evidence disclosure exposed context and next step.
- Browser: failed refresh retained the prior observation and showed failure.
- Browser: live, last-known, CLI-unavailable and unlinked registry states
  retained the persistent Tessl identity; mixed fixture exposed all six gate
  status types.
- Browser: short-height preview with expanded command was scrolled to the
  registry card; persistent Tessl branding remained visible. Screenshot:
  `/private/tmp/skillsbar-prototype-short-logo.png`.

Light appearance and the all-passed fixture are implemented but did not receive
a complete final visual acceptance pass: Chrome use changed during that check.
VoiceOver, OS accessibility preferences, frame timing and native integration
were not tested. JavaScript syntax passed after the final focus-preservation,
context-preservation and copy-retry refinements. Console diagnostics were not
available through native browser inspection; no console-clean claim is made.

Only files in this prototype directory changed for this request. No app build,
relaunch, selection change or runtime evidence-link mutation was performed.
`ReleaseEvidenceView.swift` retains SHA-256
`b739be058ff1012bf29d8eecbcaec2e1dddc7fca747d7cdb7a831a04562689d3`.
