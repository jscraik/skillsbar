# SkillsBar evidence walkthrough

A landing page and interactive nine-stage inspector matching the compact 04B native app.
The native menu-bar app remains the product demo.

## Interaction model

- Select one of nine stages to inspect details. Arrow keys work while a stage
  button is focused; normal page scrolling and text selection remain available.
- Choose “Security review required” or “Identity missing” using the labelled demo
  scenario controls inside the inspector. Changing scenario resets selection to its next required gate.
- Selected details reveal over 160ms without moving the grid or registry. Reduced
  Motion disables the animation. Navigation collapses to an Explore menu at 900px.
- The product-proof section crops the native capture to its evidence, action, and
  Tessl summary, with three accompanying annotations.
- Stage selection never changes evidence. Security uses the native visual-comparison
  fixture with an unavailable registry; identity uses the supported demo baseline
  (version 0.2.0, score 66, lift 1.28x). Downstream identity explanations summarise
  the evidence model rather than claiming to be raw receipts.
- The security fixture's illustrative command is not presented as an executable
  command. Identity exposes its real copy-only SDK start command.
- Copy confirmation resets after 1.8 seconds; denied clipboard access reveals the
  selectable command with a manual-copy instruction.
- Marketing content is visible without JavaScript. No camera animation or automatic
  scenario advancement is used.
- This site executes no SDK commands or production operations.

## Proof boundary

- `CONCEPT MOCKUP · NOT RUNTIME EVIDENCE` identifies the system diagram.
- `Native app · Fixture capture` identifies a render from the packaged app with `SKILLSBAR_DEMO_MODE=1`, `--snapshot-dark`, and `--snapshot`. It does not prove live menu-bar interaction.
- The expanded nine-gate SVG is a concept evidence atlas, not live product proof.
- The Tessl baseline remains visually separate from current local proof.
- SkillsBar exposes evidence and the next command; the release decision remains
  human.

To regenerate the app snapshot, run these commands from the repository root.
The first step packages the app without launching or stopping a running copy;
the executable then renders the deterministic fixture to the site asset
without opening the menu bar. Snapshot export uses the fixed 460 × 586-point canvas
even when the live menu bar adapts to a shorter display:

```bash
SKILLSBAR_BUILD_ROOT="$PWD/.build/skillsbar-demo" bash script/package_app.sh debug
SKILLSBAR_DEMO_MODE=1 "$PWD/.build/skillsbar-demo/SkillsBar.app/Contents/MacOS/SkillsBar" \
  --snapshot-dark --snapshot sites/skillsbar-walkthrough/public/skillsbar-demo-render.png
cwebp -lossless -exact -m 6 \
  sites/skillsbar-walkthrough/public/skillsbar-demo-render.png \
  -o sites/skillsbar-walkthrough/public/skillsbar-demo-render.webp
```

The page serves the WebP, so regenerate it whenever the source PNG changes.
The conversion uses the `cwebp` command-line tool. It reproduces the committed
WebP byte for byte from the committed PNG; a fresh app capture can change as
the app evolves, so inspect it before replacing the site fixture.

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

The browser check uses a locally installed Chrome. It covers layout at six
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
