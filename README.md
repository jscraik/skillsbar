# SkillsBar

SkillsBar is a native macOS menu-bar app for watching local Skills SDK evidence without flattening separate proof lanes. It renders the selected skill's local package, scenario, security, inventory, and Tessl registry state in a compact SwiftUI popover.

The app is currently a local prototype. It builds and launches from this checkout, reads the agent-skills repository on disk, and keeps local SDK evidence separate from Tessl registry evidence.

## What It Shows

- **Local package quality** from `./bin/ask skills package verify <skill> --json --robot`.
- **Local scenario impact** from `./bin/ask sdk eval scenario-quality <skill> --preview --json --robot`.
- **Local security posture** from `./bin/ask sdk security risk-modes <skill> --preview --json --robot`.
- **Skill inventory coverage** by scanning `Skills/**/SKILL.md` in the configured agent-skills repository.
- **Tessl registry status** when the `tessl` CLI is available, authenticated, and registry search succeeds.

These lanes are intentionally independent. A clean registry result does not prove local source safety, and local build or test proof does not prove hosted CI, registry publication, notarization, or review readiness.

## Requirements

- macOS 14 or newer.
- SwiftPM from Xcode or the active developer toolchain.
- A local agent-skills checkout. The default is `/Users/jamiecraik/dev/agent-skills`.
- Optional: `tessl` CLI access for live registry status.

## Run

```bash
cd /Users/jamiecraik/dev/skillsbar
./Launch.command
```

You can also double-click `Launch.command` in Finder.

The launcher builds the Swift package, creates `SkillsBar.app` under `SKILLSBAR_BUILD_ROOT`, signs it locally with ad hoc signing, and opens it through LaunchServices. The default build root is:

```text
/Users/jamiecraik/.codex/usage-data/skillsbar
```

For a build-only check that does not open the app:

```bash
NO_OPEN=1 ./Launch.command
```

If LaunchServices cannot open the app from the current process, the launcher writes a `SkillsBar.launch-receipt.json` file in the build root with the app path and a manual `open -n` command.

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

For fixture-based Tessl UI work, set `TESSL_REGISTRY_FIXTURE=1` or `TESSL_REGISTRY_FIXTURE_SCORE=<0-100>` with the optional fixture variables used in `DashboardLoader.swift`.

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

| Path                                                                                     | Purpose                                                                                                |
| ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| `Package.swift`                                                                          | Swift package definition for the app, core library, and tests.                                         |
| `Launch.command`                                                                         | Build, bundle, sign, and LaunchServices entrypoint.                                                    |
| `script/build_and_run.sh`                                                                | Convenience wrapper for run, debug, logs, telemetry, and live verify modes.                            |
| `Sources/SkillsBar`                                                                      | SwiftUI app, models, services, stores, resources, and views.                                           |
| `Sources/SkillsBarCore`                                                                  | Shared shell execution and JSON parsing helpers.                                                       |
| `Tests/SkillsBarCoreTests`                                                               | Unit tests for core shell behavior.                                                                    |
| `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md`                    | Implementation-handoff visual and behavior spec for the review popover.                                |
| `.harness/reviews/2026-07-09-review-popover-3lane-synthesis.md`                          | Three-lane implementation handoff for the final-polish review popover refactor.                        |
| `.harness/reviews/2026-07-09-review-popover-pass3-synthesis.md`                          | Pass-three review closeout separating spec/doc handoff defects from remaining implementation blockers. |
| `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-implementation-handoff.png` | Current full-height implementation-handoff mockup referenced by the review popover spec.               |
| `.harness/media/2026-07-09-skills-sdk-menubar-review-popover-final-polish.png`           | Earlier final-polish mockup retained as historical comparison evidence.                                |
| `.harness/media/2026-07-09-skills-sdk-menubar-final-mockup.png`                          | Earlier persisted mockup retained as historical comparison evidence.                                   |

## Development Notes

- Keep menu-bar launch truth, SwiftPM build truth, unit-test truth, live UI proof, Tessl registry proof, and hosted readiness as separate lanes.
- Do not route Computer Use directly through a client notifier from this project; keep Computer Use behind `SkyComputerUseService` when adjacent Codex config work appears.
- Do not edit `.codex/environments/environment.toml` directly; it is generated.
- Treat `.harness` artifacts as supporting project context. Refresh runtime evidence before using the implementation-handoff spec as runtime proof.
- For the review popover, read the spec and current implementation-handoff mockup first, then the three-lane synthesis for component boundaries, fixture requirements, copy-command guardrails, and validation route. Read the pass-three synthesis for the review history behind the now-resolved spec decisions and the remaining product-code blockers.
- Keep generated app bundles and build output out of the repository; `dist/` is ignored and the default app bundle lives under `~/.codex/usage-data/skillsbar`.

## Proof Boundaries

Passing `swift build`, `NO_OPEN=1 ./Launch.command`, or `swift test` proves only the local lane that command exercises. It does not prove:

- Hosted CI status.
- Tessl private-registry authentication or publication state.
- macOS distribution signing or notarization.
- Review-thread, tracker, or merge readiness.
- Menu-bar visibility on every desktop arrangement.

For UI changes, closeout should include fresh runtime evidence from the live app, not only generated mockups or historical screenshots.
