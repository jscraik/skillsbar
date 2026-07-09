---
schema_version: 2
---

# SkillsBar Agent Instructions

## Scope

These instructions apply to the whole `skillsbar` repository.

SkillsBar is a local macOS SwiftUI menu-bar prototype for Skills SDK evidence visibility. Treat it as a live local app, not as a scratch rewrite. Keep local build, launch, UI, registry, hosted, and review-readiness truth separate.

## Discovery

1. Read this file and `README.md` before editing.
2. Inspect `Package.swift`, `Launch.command`, and the specific `Sources/**` or `Tests/**` files in scope.
3. For UI or behavior work, check `.harness/specs/2026-07-09-skills-sdk-menubar-review-popover-spec.md` and its referenced mockup before changing popover semantics.
4. Treat `.codex/environments/environment.toml` as generated. Do not edit it directly.

## Repo Rules

- Prefer current repo evidence and command output over memory or prior prototype assumptions.
- Preserve unrelated dirty or untracked work. This repository may start on an unborn branch with all files untracked.
- Keep edits narrowly scoped to the requested surface.
- Use `zsh -lc` for shell commands and invoke shell scripts explicitly with `bash` when running them through automation.
- Use `rg` or `rg --files` for discovery.
- Use `apply_patch` for manual file edits.
- Do not put generated app bundles, SwiftPM build output, raw telemetry, or local-only runtime databases into durable docs or commits unless explicitly requested.
- Do not claim hosted CI, Tessl publication, review-thread resolution, merge readiness, notarization, or UI runtime proof unless that lane was checked in the current closeout window.

## Runtime And Data Boundaries

- Default data repo: `/Users/jamiecraik/dev/agent-skills`.
- Default selected skill: `Skills/agent-ops/improve-agent-native/SKILL.md`.
- Override the data repo with `AGENT_SKILLS_ROOT`.
- Override the selected skill with `AGENT_SKILL_PATH` or `SELECTED_SKILL_PATH`.
- Default build root: `/Users/jamiecraik/.codex/usage-data/skillsbar`, controlled by `SKILLSBAR_BUILD_ROOT`.
- Computer Use is adjacent workstation infrastructure, not this app's direct runtime path. Keep it routed through `SkyComputerUseService` if related config work appears.

## Validation

Run the narrowest relevant command first:

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

For live UI launch proof, use:

```bash
script/build_and_run.sh --verify
```

Report validation as `Command: <exact command> -> pass|fail|blocked (<reason>)`. State what each command proves and what it does not prove.

## Documentation

- README claims must map to live files, scripts, or inspected source.
- Keep local absolute paths explicit when they are true for this workstation-only prototype, but do not treat them as portable release proof.
- For substantial docs, preserve proof boundaries: local build/test evidence, Tessl registry state, hosted CI, and review readiness are separate lanes.

## Harness Context

The `.harness` directory contains project context and design artifacts. The current review-popover spec is draft supporting evidence, not runtime proof. Before implementing or closing UI changes from it, refresh against the live app and report screenshot, clipboard, focus, reduced-motion, and height evidence when applicable.
