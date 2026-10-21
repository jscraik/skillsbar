# Recorded prototype review — 21 October 2026

## Context

This is the isolated SkillsBar browser design, used to inspect SDK evidence and
saved Tessl observations. It is not the running native app. Review evidence:
the actual Safari interactions, Borumi working footage and the inspected local
JavaScript/CSS. No usability study, performance benchmark or accessibility audit
is implied.

## First impressions

The previous overview repeated the installed candidate and selected stage above
the grid. A copy confirmation could reduce the available grid height. The large
registry results were also labelled Live despite being a saved fixture. These
issues affected orientation and evidence meaning before decorative polish.

## Visual design

- Removed redundant stage navigation from the overview; retained it in detail
  views. All nine stages and the evidence count have a clearer reading order.
- Kept one horizontal Tessl results section and the supplied wordmark. Removed
  the added Registry text from the wordmark at Jamie's request.
- Set the dark Tessl section's cyan independently of the light page theme.
  This fixes the observed dark-on-dark badge treatment; contrast has not been
  measured or certified.
- Kept copy actions visually secondary and preserved the app/menu-bar icons.

## Interface design

- Added previous/next stage controls so sequential inspection does not require
  repeated trips through the overview. End controls disable at gates 1 and 9.
- Reset a newly selected detail view to its beginning. Expanding a command
  brings its code into the scroll area while retaining the stage title.
- Retained the search query and focus across render-driven copy feedback.
  Added an explicit current-selection label and Enter selection from search.
- Relabelled Live fixture results as Saved snapshot and the artificial
  observation age as saved observation. Refresh feedback says Preview refreshed.

## Consistency and conventions

The same stage controls operate across all nine gates. Search remains grouped
by origin/plugin and respects the environment pin. Copying never executes a
command. The browser chooser is a prototype side panel; it is not proof that a
native macOS menu behaves this way.

## User context

Jamie needs to compare installed candidates with checked evidence and capture
legible product footage. A registry score must not be mistaken for SDK gate
clearance or a fresh provider call. The design therefore retains candidate
versions, stale/unproven states and the registry/SDK distinction.

## Top opportunities and limits

The supported navigation, command-reveal and search-persistence issues were
repaired. Further work should compare the side-panel chooser with the eventual
native implementation, test VoiceOver and measured contrast, and verify tiny
menu-bar rasterisation. These are unverified, not asserted failures. Motion is
deliberately minimal; no performance improvement is claimed.

Methods: Emil Kowalski Design Engineering for interaction continuity and
feedback; Emil AI for UI forms/typography guidance for search and hierarchy;
Josh Puckett's Interface Craft through the Interfacecraft critique/refinement
lenses. This report contains application findings, not private course content.

## Validation and recording boundaries

- `node --check verification/prototypes/prototype.js` — pass.
- `python3 verification/prototypes/serve.py --check` — pass.
- `git diff --check` — pass.
- Safari: all nine detail views and returns; forward/backward stepper through
  all gates with disabled endpoints; command reveal and copy; search retained
  across copy feedback; copy failure/retry and simulated refresh failure retaining
  the observation. Light and short-height views were inspected during the pass.
- The working Borumi export is `recordings/skillsbar-test-and-fix-2026-10-21.mp4`:
  63.296 seconds, H.264, 1920×1080, 60 fps. It includes earlier design states.
- The separate revised walkthrough is exported from its own Borumi project.
  `recordings/skillsbar-revised-walkthrough-2026-10-21.mp4` is 22.912 seconds,
  1920×1080 at 60 fps. The square `skillsbar-revised-social-1080.mp4` derivative
  crops that real footage with FFmpeg, removes its unused audio track and adds
  charcoal padding at 1080×1080; it does not fabricate interactions. Beginning,
  intermediate and final frames of the Borumi export were inspected.
  Editable local copies are `recordings/skillsbar-test-and-fix.bmprojbundle`
  and `recordings/skillsbar-revised-walkthrough.bmprojbundle`.
  Recordings are local, not posted or committed. No terminal editing is shown
  in the footage: it records the real baseline and revised browser interactions.
- Native app sources, build and running process were not changed by this work.
