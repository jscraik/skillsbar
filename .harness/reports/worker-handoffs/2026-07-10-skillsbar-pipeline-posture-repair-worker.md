# SkillsBar pipeline-posture repair Worker handoff

```yaml
schema: bounded-child-lane/v1
artifact_id: worker-2026-07-10-skillsbar-pipeline-posture-repair
date: 2026-07-10
task: Worker-SkillsBar Pipeline Posture Repair
status: repaired_with_environment_validation_blockers
repair_findings:
  - QA-001
  - QA-002
changed_files:
  - Sources/SkillsBar/Services/DashboardLoader.swift
  - Tests/SkillsBarTests/ReviewPopoverTests.swift
  - .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md
preserved_allowed_file:
  - Sources/SkillsBar/Models/DashboardModels.swift
```

## Repair summary

QA-001 is repaired at the loader/evidence boundary for both asynchronous and
synchronous loading. `collectEvidenceAsync` and `collectEvidence` compute the
governed-input candidate fingerprint before package, scenario, and security
collection starts. Immediately after those local results are collected and
parsed, `pipelineCandidate` re-enumerates the governed inputs and recomputes the
current candidate fingerprint.

Collected baseline and security receipts retain only the pre-collection
fingerprint. When the post-collection fingerprint matches, the model accepts
those receipts as current. When it differs, the existing `PipelineCandidate`
gating marks those collected receipts stale, leaves later stages unproven, and
awards every affected stage zero. A later fingerprint can no longer certify
command output collected for the earlier candidate.

QA-002 is repaired by using Swift interpolation in the later-stage action:
`Establish current \(stage.title.lowercased()) evidence after earlier stages
pass.` The first active unproven stage after baseline and security pass is now
`oss-local proof`, with concrete rendered guidance rather than the literal
`(stage.title.lowercased())` expression.

## Regression coverage

- `testLoaderRejectsEvidenceWhenGovernedInputChangesDuringCollection` creates a
  governed `SKILL.md` fixture, changes it inside the controlled evidence
  collection closure, and asserts that baseline/security are stale, all later
  receipts are unproven, the evidenced count is zero, and posture is zero.
- `testFirstActiveStageAfterSecurityPassesHasInterpolatedGuidance` uses a stable
  governed fixture with passing baseline/security evidence and asserts that
  `ossLocal` is the first active stage and its next action is the interpolated
  `oss-local proof` guidance.

## Validation evidence

Command: `HOME=/private/tmp/skillsbar-qa-test-home XDG_CACHE_HOME=/private/tmp/skillsbar-qa-test-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-qa-test-clang-cache DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer swift test --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-qa-test-build-no-debug -Xswiftc -gnone --filter "ReviewPopoverTests.test(LoaderRejectsEvidenceWhenGovernedInputChangesDuringCollection|FirstActiveStageAfterSecurityPassesHasInterpolatedGuidance)"` -> blocked (native SwiftPM emitted Xcode FSEvents and inaccessible user-cache warnings, entered `Building for debugging...` and reached build planning/resource steps, then produced no compiler or test progress for several bounded minutes; terminated with exit 130. No regression test result was produced.)

Command: `HOME=/private/tmp/skillsbar-home XDG_CACHE_HOME=/private/tmp/skillsbar-xdg CLANG_MODULE_CACHE_PATH=/private/tmp/skillsbar-clang-cache swift build --build-system native --disable-sandbox --build-path /private/tmp/skillsbar-native-build` -> blocked (canonical build emitted inaccessible SwiftPM manifest-cache warnings, entered `Building for debugging...`, reached `[5/9] Write swift-version--1AB21518FC5DEDBE.txt`, then produced no compiler progress for several bounded minutes; terminated with exit 130.)

Command: `/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc -frontend -parse Sources/SkillsBar/Services/DashboardLoader.swift Tests/SkillsBarTests/ReviewPopoverTests.swift` -> pass (both edited Swift files passed syntax parsing.)

Command: `/Library/Developer/CommandLineTools/usr/bin/swiftc -emit-module -parse-as-library -target arm64-apple-macosx14.0 -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX27.sdk -module-cache-path /private/tmp/skillsbar-repair-typecheck-module-cache -module-name SkillsBarCore -emit-module-path /private/tmp/skillsbar-repair-typecheck-modules/SkillsBarCore.swiftmodule Sources/SkillsBarCore/*.swift` -> pass (built a compiler-matched temporary `SkillsBarCore` module for fallback typechecking.)

Command: `/Library/Developer/CommandLineTools/usr/bin/swiftc -frontend -typecheck -parse-as-library -target arm64-apple-macosx14.0 -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX27.sdk -module-cache-path /private/tmp/skillsbar-repair-typecheck-module-cache -I /private/tmp/skillsbar-repair-typecheck-modules -module-name SkillsBar -enable-testing @/private/tmp/skillsbar-qa-test-build-no-debug/arm64-apple-macosx/debug/SkillsBar.build/sources` -> pass (the complete SkillsBar source target, including the repaired async/sync loader boundary, passed fallback typechecking.)

Command: `/Library/Developer/CommandLineTools/usr/bin/swiftc -frontend -typecheck -parse-as-library -target arm64-apple-macosx14.0 -sdk /Library/Developer/CommandLineTools/SDKs/MacOSX27.sdk -module-cache-path /private/tmp/skillsbar-repair-typecheck-module-cache -I /private/tmp/skillsbar-repair-typecheck-modules -F /Applications/Xcode-beta.app/Contents/Developer/Platforms/MacOSX.platform/Developer/Library/Frameworks -module-name SkillsBarTests -enable-testing @/private/tmp/skillsbar-qa-test-build-no-debug/arm64-apple-macosx/debug/SkillsBarTests.build/sources` -> blocked (the standalone CommandLineTools fallback cannot import Xcode's Swift XCTest overlay; it sees only Objective-C assertion macros and reports `cannot find 'XCTAssertEqual' in scope` throughout the pre-existing test file. This fallback cannot prove test-target typechecking.)

Command: `git diff --check` -> pass (no whitespace diagnostics.)

Command: `rg -n "case candidateBaseline|case securityReview|case ossLocal|case ossCloud|case tesslStaging|case liveScoreAndRuntime|return 15|return 25|return 20|return 10" Sources/SkillsBar/Models/DashboardModels.swift` -> pass (the six approved stages and weights remain `15/25/20/20/10/10`.)

Command: `rg -n "Historical registry baseline|TesslLogoView|SkillsSDKLogoView|postureScore|registryScore" Sources/SkillsBar/Views/DashboardView.swift Sources/SkillsBar/Models/DashboardModels.swift` -> pass (the inspected implementation still contains the custom Skills SDK/Tessl icon paths, historical-not-proof disclaimer, local posture calculation, and separate registry-score surface.)

## Remaining blockers

- The two new XCTest regressions did not execute because the native SwiftPM/Xcode
  build stopped making progress before source compilation completed. This is an
  environment/tooling blocker; it is not classified as a product-test pass or
  failure.
- The canonical build likewise did not complete. The full source target did
  pass a compiler-matched direct typecheck fallback.
- No canonical full test suite, `NO_OPEN=1 ./Launch.command`, or live
  `MenuBarExtra` verification was completed in this repair retry.

## Claims boundary

This handoff claims only the bounded QA-001/QA-002 source repair, added regression
coverage, passing syntax/source typechecks, passing whitespace inspection, and
static preservation of the approved stage weights, gating model, icon references,
and historical Tessl exclusion boundary. It does not claim that the new tests
executed, the canonical build/test lanes passed, a live menu-bar session ran,
clipboard/focus/motion behavior was observed, or any hosted CI, Tessl, packaging,
release, review, merge, staging, commit, push, publication, or notarization state
was checked or changed.

WROTE: .harness/reports/worker-handoffs/2026-07-10-skillsbar-pipeline-posture-repair-worker.md
