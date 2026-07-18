# SkillsBar

SkillsBar is a native macOS menu-bar app for watching local Skills SDK evidence without flattening separate proof lanes. It renders the selected skill's canonical package identity, validation, security, eval preparation, durable downstream receipts, runtime proof, inventory, and Tessl registry state in a compact SwiftUI popover.

The app is currently a local prototype with a release-capable packaging path. It builds and launches from this checkout, reads the agent-skills repository on disk, and keeps local SDK evidence separate from Tessl registry evidence. A public release still requires Jamie's Developer ID certificate and Apple notarization credentials.

## What It Shows

- **Candidate identity** from the non-mutating `./bin/ask sdk package build <skill> --json --robot` receipt and its canonical `package_digest`.
- **Mechanical validation** from both `./bin/ask skills package verify <skill> --json --robot` and `./bin/ask skills audit <skill> --level strict --json --robot`.
- **Local security posture preview** from the candidate-bound `./bin/ask sdk security risk-modes <skill> --preview --json --robot` receipt. This is advisory; gate 3 proof requires the full governed security receipt.
- **Eval preparation** from scenario-quality, scorer-quality, and scorer-calibration preview receipts collected in the same refresh window.
- **Eval local, Eval cloud, and Tessl staging proof** from the canonical `.harness/evidence/handoff/<skill>/gate-chain.json` and its governed release receipts.
- **Runtime truth** from `.harness/evidence/runtime-proof/<skill>/<runtime>/runtime-card.json` only when the card proves the installed digest, doctor result, and observed behavior for the current package digest.
- **Skill inventory coverage** by scanning `Skills/**/SKILL.md` in the configured agent-skills repository.
- **Tessl registry status** when the `tessl` CLI is available, authenticated, and registry search succeeds.

These lanes are intentionally independent. Every downstream receipt must use the canonical gate-chain order, remain inside the configured repository, include its proof and non-proof boundaries, resolve every evidence reference, and carry exactly the current package digest. Eval local, Eval cloud, and Tessl staging must also identify the same scenario set. Missing, malformed, unbound, or mixed-digest evidence stays unproven or stale. A clean registry result does not prove local source safety, and local build or test proof does not prove hosted CI, registry publication, notarization, or review readiness.

## Requirements

- macOS 14 or newer.
- SwiftPM from Xcode or the active developer toolchain.
- A local agent-skills checkout. The default is `/Users/jamiecraik/dev/agent-skills`.
- Optional: `tessl` CLI access for live registry status.

SkillsBar is not App-Sandboxed: it reads the configured Skills SDK checkout and runs its read-only SDK checks locally. For Tessl, it prefers `TESSL_BIN` when set, then the current user's `~/.local/bin/tessl`, then `PATH`. Keep `SKILLSBAR_REVIEW_FIXTURE` unset for normal use; that variable is reserved for deterministic tests and mockup work.

SkillsBar never automatically runs provider-backed `oss-local` or `oss-cloud` evals, Tessl staging/publication, runtime installation, or runtime-proof commands when the menu opens. Those operations may cost money, require credentials, or mutate external/runtime state, so the app consumes their durable governed receipts instead. A live Tessl CLI search is a registry observation even when the result has a version mismatch or no version. Candidate-bound publication/score receipts, package/registry version equality, and governed registry visibility remain requirements for promotion and identity verification.

## Run

```bash
cd /Users/jamiecraik/dev/skillsbar
./Launch.command
```

You can also double-click `Launch.command` in Finder.

The launcher serializes concurrent builds, stops an existing instance, delegates bundle construction to `script/package_app.sh`, signs the development app ad hoc, opens it through LaunchServices, and verifies that the process remains running. If LaunchServices is unavailable in the caller's session, it falls back to launching the bundled executable directly and records which path was used. The default build root is:

```text
~/.codex/usage-data/skillsbar
```

For the supported hackathon walkthrough, launch the real menu-bar app with deterministic demo evidence:

```bash
./script/build_and_run.sh --demo
```

This mode launches the packaged `MenuBarExtra`, selects the deterministic Gate 1 nine-gate fixture, and shows a `DEMO FIXTURE` disclosure in the popover. It prefers LaunchServices and accepts the launcher's sustained direct-executable fallback when LaunchServices is unavailable; the receipt records the exact method. Click the Skills SDK document icon in the macOS menu bar to reveal it. The receipt also records `evidence_mode` as `deterministic_demo_fixture`; the fixture demonstrates the product flow but is not live SDK, Tessl, hosted CI, notarization, or review-readiness proof. Use `--verify`, rather than `--demo`, when LaunchServices itself is the behavior under test.

The timed judge walkthrough and proof-boundary answers are in [`DEMO.md`](DEMO.md).

For a build-only check that does not open the app:

```bash
NO_OPEN=1 ./Launch.command
```

Every launch attempt writes `SkillsBar.launch-receipt.json` in the build root. The receipt distinguishes a LaunchServices launch, a direct-executable fallback, and a blocked launch. A direct fallback is useful for headless development automation, but `script/build_and_run.sh --verify` accepts only a sustained LaunchServices launch as live MenuBarExtra evidence.

To package without launching:

```bash
script/package_app.sh debug
```

Set `ARCHES="arm64 x86_64"` and use the `release` configuration to create a universal local package. This remains ad hoc signed unless `SKILLSBAR_SIGNING=identity` and `APP_IDENTITY` are supplied explicitly.

## Distribute

`script/release.sh` is the production distribution boundary. It creates a universal release build, signs with hardened runtime and a timestamp, submits it to Apple notarization, staples the ticket, verifies the signature and distribution policy, and produces a `ditto` zip under `dist/`.

Store notarization credentials in a keychain profile once:

```bash
xcrun notarytool store-credentials skillsbar-notary
```

Then release with the exact Developer ID identity installed in Keychain Access:

```bash
APP_IDENTITY="Developer ID Application: Your Name (YOURTEAMID)" \
NOTARY_PROFILE=skillsbar-notary \
SKILLSBAR_BUNDLE_ID="com.yourcompany.skillsbar" \
script/release.sh
```

The interactive prompts store the Apple ID, team ID, and app-specific password in the login keychain. The script fails before publication when the identity or keychain profile is absent. It does not create a GitHub release, update feed, Homebrew cask, or automatic-update channel; those are deliberately deferred until SkillsBar has a stable public bundle identifier and a first notarized artifact.

## Configure The Data Source

By default, SkillsBar looks for `Skills/agent-ops/improve-agent-native/SKILL.md` in `/Users/jamiecraik/dev/agent-skills`.

Use another agent-skills checkout:

```bash
AGENT_SKILLS_ROOT=/path/to/agent-skills ./Launch.command
```

Use another skill:

```bash
AGENT_SKILL_PATH=Skills/agent-ops/technical-writer/SKILL.md ./Launch.command
```

`SELECTED_SKILL_PATH` is also accepted for the selected skill path. Paths must point to an existing `Skills/**/SKILL.md` file in the configured root; otherwise the app falls back to the default skill.

When no launch-time skill path is set, use the circular-arrow chooser beside the skill name to select any local `Skills/**/SKILL.md`; SkillsBar persists that choice. A launch-time `AGENT_SKILL_PATH` or `SELECTED_SKILL_PATH` intentionally pins the selection. The app refreshes the selected skill immediately after its directory changes, and also refreshes on its five-minute live-data interval.

If Tessl is installed outside the normal user-local location, point the app at it explicitly:

```bash
TESSL_BIN=/absolute/path/to/tessl ./Launch.command
```

For fixture-based Tessl UI work, set `TESSL_REGISTRY_FIXTURE=1` or `TESSL_REGISTRY_FIXTURE_SCORE=<0-100>` with the optional fixture variables used in `DashboardLoader.swift`. Add `TESSL_REGISTRY_FIXTURE_MODE=cached` to exercise the CLI-unavailable historical treatment.

For product demos, use the supported `./script/build_and_run.sh --demo` path above. For deterministic test and mockup work only, `SKILLSBAR_REVIEW_FIXTURE=live` (or `1`) bypasses live package, scenario, security, and registry parsing before constructing the model, so snapshots consistently render candidate identity as the active gate, held mechanical/security/eval-preparation observations, registry score 66, and the canonical SDK-start command. Use `SKILLSBAR_REVIEW_FIXTURE=no-cli` to render the same last-known registry metrics with `CLI UNAVAILABLE` and `Historical external baseline · not proof for this candidate.`

A successful live Tessl CLI search stores only sanitized registry fields (version, score, Quality, Impact, Security, eval count, multiplier, and visibility) in local preferences. If the CLI later becomes unavailable, SkillsBar can show that last-known snapshot as historical context. It does not cache credentials, raw command output, or package contents, and cached registry data never promotes a local pipeline gate.

`Tests/SkillsBarTests/Fixtures/` retains sanitized Tessl responses for Private, Public, and missing-visibility registry records. The focused popover tests also render the production `DashboardView` and compare it with the retained implementation snapshot, so model-contract and visible-layout drift fail together.

Security presentation is severity-first and shared by local and registry evidence: failed/critical is red, flagged is amber, advisory is cyan, passed is green, and unknown is pending gray. The test fixtures include an ambiguous registry payload to prove unrelated nested fields cannot override the canonical result. Adaptive render coverage exercises advisory, public, missing-visibility, accessibility-sized text, Reduce Transparency, and Increased Contrast variants.

## Validation

Run the narrow checks first, then widen only when the changed surface requires it.

```bash
HOME=/private/tmp/skillsbar-home \
XDG_CACHE_HOME=/private/tmp/skillsbar-xdg \
CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache \
swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build
```

```bash
NO_OPEN=1 ./Launch.command
```

```bash
HOME=/private/tmp/skillsbar-test-home \
XDG_CACHE_HOME=/private/tmp/skillsbar-test-xdg \
CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-test-clang-cache \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-test-build
```

`script/build_and_run.sh --verify` launches the app and checks for a running `SkillsBar` process. Use it only when a live macOS UI launch is appropriate for the current task.

## Project Layout

| Path                                                                                     | Purpose                                                                                                  |
| ---------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `Package.swift`                                                                          | Swift package definition for the app, core library, and tests.                                           |
| `Launch.command`                                                                         | Build, bundle, sign, and LaunchServices entrypoint.                                                      |
| `script/package_app.sh`                                                                  | Deterministic development/release bundle assembly, architecture verification, and signing boundary.      |
| `script/release.sh`                                                                      | Universal Developer ID signing, notarization, stapling, verification, and release-zip boundary.          |
| `script/build_and_run.sh`                                                                | Convenience wrapper for run, deterministic demo, debug, logs, telemetry, and live verify modes.          |
| `version.env`                                                                            | Shared marketing version and monotonically increasing build number.                                      |
| `Sources/SkillsBar`                                                                      | SwiftUI app, models, services, stores, resources, and views.                                             |
| `Sources/SkillsBarCore`                                                                  | Shared shell execution and JSON parsing helpers.                                                         |
| `Tests/SkillsBarCoreTests`                                                               | Unit tests for core shell behavior.                                                                      |
| `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md`                    | Implementation-handoff visual and behavior spec for the review popover.                                  |
| `.harness/reviews/2026-07-09-review-popover-3lane-synthesis.md`                          | Three-lane implementation handoff for the final-polish review popover refactor.                          |
| `.harness/reviews/2026-07-09-review-popover-pass3-synthesis.md`                          | Pass-three review closeout separating spec/doc handoff defects from remaining implementation blockers.   |
| `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-implementation-handoff.png` | Current full-height implementation-handoff mockup referenced by the review popover spec.                 |
| `.harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png`              | Deterministic `404 x 560` app-rendered implementation snapshot; not live MenuBarExtra interaction proof. |
| `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png`           | Earlier final-polish mockup retained as historical comparison evidence.                                  |
| `.harness/media/2026-07-09-skills-sdk-menubar-final-mockup.png`                          | Earlier persisted mockup retained as historical comparison evidence.                                     |

## Development Notes

- Keep menu-bar launch truth, SwiftPM build truth, unit-test truth, live UI proof, Tessl registry proof, and hosted readiness as separate lanes.
- Do not route Computer Use directly through a client notifier from this project; keep Computer Use behind `SkyComputerUseService` when adjacent Codex config work appears.
- Do not edit `.codex/environments/environment.toml` directly; it is generated.
- Treat `.harness` artifacts as supporting project context. Refresh runtime evidence before using the implementation-handoff spec as runtime proof.
- For the review popover, read the spec and current implementation-handoff mockup first, then the three-lane synthesis for component boundaries, fixture requirements, copy-command guardrails, and validation route. Read the pass-three synthesis for the review history behind the now-resolved spec decisions and the remaining product-code blockers.
- Keep generated app bundles and build output out of the repository; `dist/` is ignored and the default app bundle lives under `~/.codex/usage-data/skillsbar`.
- Keep `Launch.command` as the development runner, `script/package_app.sh` as the sole bundle-construction path, and `script/release.sh` as the credentialed distribution boundary.
- Automatic updates, Homebrew distribution, launch-at-login UI, and hosted release automation should be added only after the first notarized release fixes the public bundle identifier and update ownership. They are delivery features, not substitutes for signing and notarization.

## Proof Boundaries

Passing `swift build`, `NO_OPEN=1 ./Launch.command`, or `swift test` proves only the local lane that command exercises. It does not prove:

- Hosted CI status.
- Tessl private-registry authentication or publication state.
- macOS distribution signing or notarization.
- Review-thread, tracker, or merge readiness.
- Menu-bar visibility on every desktop arrangement.

For UI changes, closeout should include fresh runtime evidence from the live app, not only generated mockups or historical screenshots.
