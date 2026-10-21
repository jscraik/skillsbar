# Historical verification: 20–21 October 2026

Prepared on 21 October 2026 against repository commit
`ad6ae1deba4965b0d058a71db64e0be36deed471`. SkillsProof was named SkillsBar
during the original observations; internal module and test names retain that name.
This is a sanitised historical summary, not a new verification run or release
clearance. Private plugin source, account identifiers, ownership records,
machine-specific paths and raw runtime evidence are deliberately excluded.

## Missing-stage finding and repair

The original receipt-gating implementation skipped an absent stage without
resetting the prerequisite chain. A later matching Passed receipt could therefore
remain Passed despite the missing prerequisite. Complete-input checks passed;
sparse-input checks exposed the defect. Initial solver execution was blocked by
missing discoverable tooling; later Java/TLC execution superseded that blocker.

The repair inserts an Unproven placeholder and clears the prerequisite state.
Later evidence is held; empty input produces nine Unproven stages. Complete
input retains its receipts. The repair and regression tests were subsequently
backed up in commit
[`2674fbf`](https://github.com/jscraik/skillsproof/commit/2674fbf976a9b4a1ad9071328b5cc7b88224aa97).
See [the gating model](../Sources/SkillsBar/Models/DashboardModels.swift) and
[regression tests](../Tests/SkillsBarTests/ReviewPopoverTests.swift).

The historical repaired TLA+ run recorded these results:

| Lane | Outcome | Generated / distinct / queued states |
| --- | --- | --- |
| Complete and restored complete | Pass | 3,613 / 1,885 / 0 each |
| Sparse and restored sparse | Pass | 35,461 / 14,425 / 0 each |
| Binding-guard negative control | Expected PassedBound violation | 2 / 2 / 0 |
| Missing-stage negative control | Expected PassedPrefix violation | 42 / 29 / 26 |

Negative-control failures demonstrate sensitivity, not baseline failure or
exhaustive safety. The model used three representative stages and six statuses;
it is not an arbitrary-size theorem or proof of concurrency, liveness, parsing,
filesystem races or the whole application. Concrete source-slice checks covered
1,728 complete assignments, 2,197 sparse assignments and every single omission
across nine stages. Historical source identities differ from current HEAD.
The runner's exit zero alone was never the solver verdict: logs required review.

## Installed evidence and interface observations

Installed discovery and checked-source linking were backed up in
[`b4b4c5e`](https://github.com/jscraik/skillsproof/commit/b4b4c5e9a1653330d253c51455606698a1dc7d32).
The implementation keeps installed-copy identity and SDK receipts separate from
Tessl observations. Exact package matching prevents unrelated search results
from supplying metrics. Retained source/runtime drift must not clear SDK gates.
See [discovery](../Sources/SkillsBar/Services/InstalledSkillDiscovery.swift),
[source evidence](../Sources/SkillsBar/Services/InstalledSourceEvidence.swift)
and [the documented evidence boundaries](../README.md).

Historical UI observations recorded grouped chooser origins and plugin versions,
an explicit missing-version label, and an elapsed-time display that updates
without fetching new evidence. The presentation changes were backed up in
[`ccb8e5c`](https://github.com/jscraik/skillsproof/commit/ccb8e5cd1469b82758d3a717a19cbd9811d30b43)
and chooser coverage in
[`0661507`](https://github.com/jscraik/skillsproof/commit/066150782ebd4b3ceb2f5e449a480c3d40a78872).
See [presentation tests](../Tests/SkillsBarTests/PresentationPolishTests.swift).
These historical observations do not establish fresh VoiceOver acceptance,
host activation, registry publication or current UI behaviour.

The [browser prototype reopening guide](prototypes/REOPEN.md) preserves the
separate design exercise. Its scores and states are illustrative snapshots;
prototype acceptance does not establish native implementation acceptance.

## Evidence reference check performed for this summary

On 21 October, the local repaired-run result, independent-run result, sparse
solver output and missing-stage negative-control output were present and read.
The sparse log explicitly reported no error and 35,461 generated / 14,425 distinct
states; the negative-control log explicitly reported a PassedPrefix violation.
The following SHA-256 values identify the retained originals without publishing
their workstation paths or contents:

| Retained private evidence | SHA-256 |
| --- | --- |
| Repaired-run result JSON | `e98a8deb92133280d51d63919454a3e40e8189033cbbecd1ad2602dfd45170b5` |
| Independent-run result JSON | `03d170b0d187168d7c86321624c281ff087bad81944de4a0d5f503e7a8e07c6c` |
| Repaired sparse solver output | `a268b17c675684cebae7f3b7dad90f6d6f1586323c1331836f9fce7f967b6859` |
| Missing-stage negative-control output | `2424e84f396c076217f23c4c55527273999d5320b015de008f4c2c265290b814` |

Hashes identify files; they do not authenticate authorship or make private
evidence publicly reproducible. Raw logs and the private model package are not
included in this commit. Historical screenshots and mutable launch receipts were
not revalidated for this summary and are not linked as durable public proof.
Repository-relative references and commit ancestry were checked locally before
commit. No fresh Swift tests, solver execution, SDK checks, app build or launch
were performed for this documentation-only change. Hosted CI, independent
current-head review and release readiness are separate, unclaimed lanes.
