# Demo site alignment verification

2026-09-30. Local implementation with desktop/mobile Chrome inspection.

## Changes delivered

- Product-first introduction and current 460 × 586 app-rendered capture.
- Interactive nine-stage navigator with separately labelled security and identity
  scenarios, stable detail row minimums, keyboard navigation, and copy feedback.
- Preserved Tessl artwork and identity fixture version/score/lift (0.2.0, 66, 1.28x).
- Security follows the native visual-reference fixture and unavailable registry;
  its illustrative command is not offered as an executable command.
- Identity explanations outside Gate 1 are explicitly described as summaries.
- Technical atlas retained as a concept appendix; social artwork now uses the app.

## Evidence

Command: `npm run lint` -> pass.

Command: `npm test` -> pass (production build and three rendered-page tests).

Command: `node --check tests/browser-smoke.mjs` -> pass (syntax only).

Command: `git diff --check` -> pass.

Command: `CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-site-clang XDG_CACHE_HOME=/private/tmp/skillsbar-site-xdg DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-site-build` -> pass.

Command: `SKILLSBAR_DEMO_MODE=1 /private/tmp/skillsbar-site-build/debug/SkillsBar --snapshot-dark --snapshot sites/skillsbar-walkthrough/public/skillsbar-demo-render.png` -> pass (current native renderer; deterministic fixture; image inspected).

Command: `cwebp -lossless -exact -m 6 sites/skillsbar-walkthrough/public/skillsbar-demo-render.png -o sites/skillsbar-walkthrough/public/skillsbar-demo-render.webp` -> pass (460 × 586, 27,976 bytes).

Command: `CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-cover-module-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer xcrun swift scripts/generate-skillsbar-cover.swift public/og.png` -> pass.

## Pending acceptance

Browser tab at http://localhost:3008 was confirmed in the plugin's tab list and
the user confirmed it was open. Browser page inspection was blocked twice by
saved-permission verification being unavailable. No alternate browser controller
was used to bypass that restriction.

The user then explicitly requested Chrome as the fallback. Chrome was launched
with the local URL. The first smoke-test run found a missing declared dependency;
`npm ci --ignore-scripts` restored the locked dependencies successfully.

Command: `npm run test:browser -- http://localhost:3008/` -> pass (375, 768, 1024,
1440px; all nine selections in both scenarios; evidence stability; registry
position within 1 CSS pixel on desktop; scenario reset; keyboard; clipboard success
and failure; image loading; no-JavaScript hero).

The same Chrome smoke check also passed after switching the local server to
`npm run start -- --port 3008`, exercising the final production build.

Desktop and mobile screenshots were captured at
`/private/tmp/skillsbar-site-1440.png` and `/private/tmp/skillsbar-site-375.png` and
visually inspected. The screenshot test is a local Chrome path, not proof that
the in-app Browser permission issue is fixed.

Pending: equal-width native/web visual comparison, 200% zoom, contrast measurements,
VoiceOver, real phone checks, and hosted link/social-preview checks.
No forms, accounts, or remote data operations are introduced. Deployment target and
deployment status are unverified; this task has not published the site.

The implementation uses the existing CSS and system fonts, native buttons, labelled
commands, semantic status colours plus text/icons, and normal page scrolling. These
are source findings, not claims of completed browser/device accessibility proof.

Dependency installation initially reported four affected packages, all rooted in
Undici through the Cloudflare development tooling. Updated exact pins to
`@cloudflare/vite-plugin@1.62.2` and `wrangler@4.144.0`; the lockfile now resolves
the patched dependency chain. Command: `npm audit --audit-level=low` -> pass
(zero vulnerabilities). Lint, production build, three rendered-page tests and the
four-width Chrome smoke check passed after the upgrade. No force upgrade was used.

Attribution is now jscraik in navigation, hero and footer, plus regenerated social
artwork. The hero's duplicate logo/name block was replaced with a concise author
line. `/private/tmp/skillsbar-site-hero.png` captures the inspected final hero.

In-app Browser DOM inspection still fails saved-permission verification. This
failure is outside the site repository; the working Chrome path does not repair
the Codex Browser permission service.

## Interface Craft refinement — 2026-09-30

Implemented the five review opportunities: an annotated native detail crop,
scenario controls inside the inspector, a 160ms opacity reveal for selected
details with Reduced Motion disabled, consolidated disclosures, quieter repository
navigation with an Explore menu at 900px, and tighter section spacing/captions.
The native detail retains the full Tessl icon, score and command.

Command: `npm run lint` -> pass.
Command: `npm test` -> pass (production build and three rendered-page tests).
Command: `npm run test:browser -- http://localhost:3008/` -> pass (375, 654,
837, 900, 1024 and 1440px; both scenarios and all stages; evidence/registry
stability; compact menu; clipboard; keyboard; reduced-motion suppression;
160ms animation when motion is allowed; no-JavaScript hero).
Command: `git diff --check` -> pass.

Inspected local screenshots: `/private/tmp/skillsbar-interface-proof.png`,
`/private/tmp/skillsbar-site-1440.png` and `/private/tmp/skillsbar-site-375.png`.
This verifies the local Chrome rendering; hosted deployment and VoiceOver remain
outside this proof.
