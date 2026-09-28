# SkillsBar evidence walkthrough

A landing page and four-view visual explainer for the SkillsBar evidence cockpit. The explainer supports judge Q&A; the native menu-bar app remains the product demo.
The page presents one deterministic candidate-identity scenario: the local Skill
has no canonical package digest at Gate 1, so every downstream receipt remains
held while the published registry baseline stays visible as separate context.

## Interaction model

- Select the four visible walkthrough beats. With the walkthrough region focused,
  use Space/Right Arrow and Left Arrow, or press `R` to return to the overview.
  Shortcuts do not override normal page scrolling outside that region.
- The evidence scenario remains fixed while the desktop camera moves across
  Build, Prove, and Ship. Mobile stacks all three groups in the overview and
  shows the selected group in chapter views. Keyboard changes are immediate;
  pointer changes use a short transform transition. Reduced Motion removes
  movement while keeping color feedback on controls.
- Both command presentations have a copy button. Copy success resets after
  1.8 seconds. If clipboard access fails, the full command remains selectable
  with a manual-copy instruction.
- Marketing sections render without scroll-triggered reveals. The walkthrough
  alone changes its camera in response to the visitor's controls.
- The candidate-identity command is a copy-only demonstration. The page does not execute
  Skills SDK commands, publish packages, access credentials, or call production
  endpoints.

## Proof boundary

- `CONCEPT MOCKUP · NOT RUNTIME EVIDENCE` identifies the system diagram.
- `SUPPORTED DEMO FIXTURE · APP-RENDERED SNAPSHOT` identifies a render from the packaged app with `SKILLSBAR_DEMO_MODE=1` and `--snapshot`. It does not prove live menu-bar interaction.
- The expanded nine-gate SVG is a concept evidence atlas, not live product proof.
- The Tessl baseline remains visually separate from current local proof.
- SkillsBar exposes evidence and the next command; the release decision remains
  human.

To regenerate the app snapshot, run these commands from the repository root.
The first step packages the app without launching or stopping a running copy;
the executable then renders the deterministic fixture to the site asset
without opening the menu bar:

```bash
SKILLSBAR_BUILD_ROOT="$PWD/.build/skillsbar-demo" bash script/package_app.sh debug
SKILLSBAR_DEMO_MODE=1 "$PWD/.build/skillsbar-demo/SkillsBar.app/Contents/MacOS/SkillsBar" \
  --snapshot sites/skillsbar-walkthrough/public/skillsbar-demo-render.png
cwebp -lossless -exact -m 6 \
  sites/skillsbar-walkthrough/public/skillsbar-demo-render.png \
  -o sites/skillsbar-walkthrough/public/skillsbar-demo-render.webp
```

The page serves the WebP, so regenerate it whenever the source PNG changes.
The conversion uses the `cwebp` command-line tool; the current committed WebP
matches the output of the command above byte for byte.

## Local validation

The page uses system fonts so building the demo does not fetch Google Fonts.
The Cloudflare development adapter keeps bindings local and disables tunnels.
The in-page icon uses a 168px WebP while the small PNG supplies the favicon.
The app snapshot uses a lossless WebP; the original PNG remains its source asset.

The `vinext`-scoped `image-size` override pins 2.0.4 because Vinext 0.0.50
pins vulnerable 2.0.2. Remove the override when a validated Vinext update
includes a patched parser. Recheck with `npm audit --audit-level=low` after
dependency updates; a clean audit covers known advisories, not application
security or hosted release readiness.

```bash
npm run lint
npm test
```

To replay the production browser smoke check, install dependencies and start
the built site in one terminal, then run the browser check in another:

```bash
npm ci --ignore-scripts
npm test
npm run start -- --port 3008
# In a second terminal:
npm run test:browser -- http://localhost:3008/
```

The browser check uses a locally installed Chrome. It covers layout at four
widths, keyboard focus and shortcuts, clipboard feedback, reduced motion,
image loading, and the no-JavaScript hero. It does not prove native menu-bar
interaction, hosted deployment, or other browser engines.

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
