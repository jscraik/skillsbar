# SkillsBar demo site alignment plan

Date: 2026-09-30
Status: local redesign implemented; Chrome acceptance recorded in REDESIGN-VERIFICATION.md.
Real-device, zoom, hosted preview, and deployment checks remain pending.

## Outcome and scope

Make the demo site recognisably match the current 04B native app: nine-stage
navigation, stable selected-stage details, one clear command action, and a complete
Tessl summary. A visitor should understand what needs attention and what to do next
without first learning the evidence architecture.

Scope: this site, its fixture presentation, screenshots, copy, and browser tests.
Native evidence rules and the installed app are not redesign targets. Deployment
status is unverified; publication is a separate, explicitly authorised step.

Use Emil design foundations for hierarchy, semantic colours, spacing, accessible
controls, and restrained surfaces. Use Emil prep-for-prod's nine lanes for the final
checklist. Use REDESIGN-VERIFICATION.md for current command results and remaining proof gaps.

## Design decisions

- Lead with the app rather than the conceptual Build / Prove / Ship rail.
- Proposed hero: “Know what your skill needs next.” Explain the nine evidence gates
  and command-copy workflow in one short paragraph. Primary action: “Explore the
  demo”; repository access is secondary.
- Page order: hero and app render; interactive navigator; local-versus-registry
  explanation; optional technical atlas; repository and project context.
- Retain the Tessl icon. Show version, package name, score, and lift when available.
  Missing data must have an honest unavailable state, not invented numbers.
- Use amber for review, green for passed, neutral for held/unproven, blue for
  actions/selection, and cyan for registry context. Status also needs text/icons.
- Preserve the current CSS approach and tokens. Subtle browser blur is optional;
  readable opaque fallbacks are required. Do not promise native macOS vibrancy.
- Stage selection changes inspected details, never the candidate's evidence.
- Default to the security-review scenario to match the recent app demonstrations;
  retain identity-missing as a separately labelled scenario. Both must be verified
  against deterministic native fixtures before their values become site content.

## 1. Establish the reference and fixture contract

- [ ] Capture the current packaged app in a deterministic scenario; record how it
  was produced and inspect it before replacing assets.
- [ ] Confirm both scenario definitions, stage labels, statuses, explanations,
  commands, and registry values against native models. Do not treat old screenshot
  values such as 94 as permanent product data.
- [x] Define typed site scenario data with separate selected-stage state.
- [x] Keep one source of site scenario values for the view and its tests; avoid
  copying separate command/status arrays into each component.
- [x] Record a desktop reference with full Tessl summary and a narrow mobile layout.

Exit: fixture meaning and visual reference agree; discrepancies are resolved before
building the interactive experience.

## 2. Refresh the page hierarchy and assets

- [x] Update `app/page.tsx` with the agreed product introduction and section order.
- [x] Regenerate `public/skillsbar-demo-render.png` and its lossless WebP using the
  existing README workflow; update intrinsic dimensions to the actual output.
- [x] Remove stale references to the 1180-point canvas from the capture instructions
  after verifying the current renderer's dimensions.
- [x] Label native captures as app-rendered fixtures and the interactive web demo
  as simulated evidence. Keep these labels concise and near the relevant surface.
- [x] Retain the technical atlas as optional supporting material. Update stale
  camera-movement explanations, captions, alt text, and Codex process copy.

Exit: the hero looks like the current app, with useful content even without JavaScript.

## 3. Replace the camera walkthrough with the focus navigator

- [ ] Refactor `app/interactive-evidence.tsx` around a 3 × 3 stage grid, selected
  detail panel, command disclosure/copy control, and Tessl summary.
- [x] Keep scenario switching distinct from stage navigation and label it “Demo
  scenario”. Reset selection to that scenario's next required stage.
- [ ] Use a stable desktop detail region sized for all nine real fixture descriptions;
  allow growth at larger text sizes and narrow widths rather than clipping.
- [x] Put next-required context beside the gate number where it fits. Provide a
  readable wrapping layout on narrow screens.
- [x] Keep the action region stable when no command exists; show honest availability
  text rather than a fake or disabled copy action.
- [x] Keep the entire Tessl summary visible in the standard desktop demo without
  an internal scroll or disclosure. On mobile, use normal page scrolling.
- [x] Support native buttons, visible focus, logical Tab order, and documented arrow
  navigation scoped to the stage selector. Never intercept normal page scrolling.
- [x] Provide copy success feedback and a selectable-command fallback on failure.
- [x] Keep keyboard selection immediate. Limit pointer effects to brief colour/opacity
  feedback; respect reduced motion and avoid animated layout dimensions.

Exit: switching among all nine stages leaves the desktop registry position stable,
and no transition creates or implies new evidence.

## 4. Visual and functional acceptance

- [ ] Compare the web inspector beside a current native capture at equal displayed
  widths: proportions, density, typography, grid, status treatment, and action placement.
- [ ] Test every stage in both scenarios, plus registry unavailable and long text.
- [x] Assert unchanged scenario evidence when selecting a different stage.
- [x] Check registry top-position stability within 1 CSS pixel for standard desktop
  fixture states; separately check no clipping at narrow widths and increased text.
- [x] Check full Tessl icon, version, package name, score, and lift before accepting
  any spacing change. This is an explicit regression gate.
- [ ] Check 375, 768, 1024, and 1440 CSS-pixel widths, 200% zoom, and keyboard-only use.
- [x] Update browser tests for selection, scenario reset, copy success/failure,
  reduced motion, image loading, and no-JavaScript hero content.

## 5. Pre-production sweep

For execution, load the matching lane files from `emil-prep-for-prod` and record
pass, fail, blocked, or not applicable with evidence; these boxes are not proof.

- [ ] Accessibility: names, focus, reading order, contrast, non-colour status cues.
- [ ] Performance: correctly sized images, reserved dimensions, no new heavy UI library.
- [ ] Mobile: touch targets, wrapping, zoom, no horizontal overflow; real-device check
  remains separate from desktop emulation.
- [ ] Forms: mark not applicable if none are introduced; test clipboard separately.
- [ ] Stability/states: unavailable data, long text, repeated selection and copying.
- [ ] Motion: keyboard immediacy, reduced motion, no unnecessary camera movement.
- [ ] Theming: readable surfaces and controls with and without blur support.
- [ ] Content: no stale screenshots, contradictory captions, placeholders, or debug UI.
- [ ] Marketing/SEO: accurate metadata, social preview, links, and image descriptions.

Run from `sites/skillsbar-walkthrough` and record exact results:

```bash
npm run lint
npm test
npm run start -- --port 3008
# In another terminal while the server is running:
npm run test:browser -- http://localhost:3008/
```

Use the existing dependency-install contract if dependencies are absent. Verify
what `npm test` covers before adding duplicate build commands. Local results do not
prove hosted behaviour or native app interaction.

## 6. Delivery and deployment boundary

- [x] Present local desktop/mobile screenshots and completed acceptance results.
- [x] Record any untested browser, device, or assistive-technology paths explicitly.
- [ ] Confirm whether a deployment already exists and identify the intended target.
- [ ] Publish only under explicit deployment authority; retain a recoverable previous
  version if replacing an existing site.
- [ ] Verify the resulting URL, assets, stage controls, clipboard behaviour, and
  repository links after deployment before calling the hosted site complete.

Owner: the SkillsBar site maintainer. Update this checklist in the implementation
task; do not mark items complete from code inspection when they require runtime proof.
