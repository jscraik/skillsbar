# SkillsBar evidence walkthrough

A landing page and four-view walkthrough for the SkillsBar evidence cockpit.
The page presents one deterministic candidate-identity scenario: the local Skill
has no canonical package digest at Gate 1, so every downstream receipt remains
held while the published registry baseline stays visible as separate context.

## Interaction model

- Select the four visible walkthrough beats or use Space/Right Arrow and Left Arrow.
- Press `R` to return to the overview.
- The evidence scenario remains fixed while the camera moves across Build, Prove,
  and Ship.
- The security command is a copy-only demonstration. The page does not execute
  Skills SDK commands, publish packages, access credentials, or call production
  endpoints.

## Proof boundary

- `CONCEPT MOCKUP · NOT RUNTIME EVIDENCE` identifies the system diagram.
- `SUPPORTED DEMO FIXTURE · NATIVE APP CAPTURE` identifies the supplied native SkillsBar screenshot and its deterministic evidence boundary.
- The expanded nine-gate SVG is a concept evidence atlas, not live product proof.
- The Tessl baseline remains visually separate from current local proof.
- SkillsBar exposes evidence and the next command; the release decision remains
  human.

## Local validation

```bash
npm run lint
npm test
```

The QR assets are generated with the pinned project-local encoder and can be
independently decoded on macOS with the Vision verifier under `scripts/`:

```bash
npm run assets:qr
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  xcrun swift scripts/verify-skillsbar-qr.swift \
  public/skillsbar-repo-qr-1024.png public/skillsbar-repo-qr-512.png
```

The thumbnail-safe social cover is generated deterministically from AppKit:

```bash
HOME=/private/tmp/skillsbar-cover-home \
CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-cover-module-cache \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
xcrun swift scripts/generate-skillsbar-cover.swift public/og.png
```
