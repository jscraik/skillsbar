# Reopen the SkillsProof design prototype

Guided evidence (`?v=3`) is the design working surface. Its layout and controls
track approved native changes; future design work starts here before authorised
native promotion. The native app remains the source of real runtime evidence.
After changing either surface, compare overview, expanded Tessl results, gate
detail, search and More before claiming parity. Review native changes in Borumi.

This directory contains the standalone prototype and all its image, CSS,
JavaScript and chooser snapshot assets. It does not depend on this chat or the
native SkillsBar process. Python 3 is required to serve it; no package installation
or build is needed. Internet access is not required for the prototype itself.

From any terminal directory, run:

```bash
bash '/Users/jamiecraik/Dev/skillsbar/verification/prototypes/Open Prototype.command'
```

Leave that terminal running, then open:

- Guided evidence: <http://127.0.0.1:8769/simplify-evidence.html?v=3>
- Menu parity: <http://127.0.0.1:8769/simplify-evidence.html?v=1>
- Evidence clarity: <http://127.0.0.1:8769/simplify-evidence.html?v=2>
- Icon comparisons: <http://127.0.0.1:8769/icon-comparison.html>
- Clean walkthrough layout: <http://127.0.0.1:8769/simplify-evidence.html?v=3&capture=1>

If port 8769 is already occupied, try the existing URL first. The launcher does
not stop another process. To use another port, append `--port 8770` to the launch
command and use 8770 in the URL. Stop your server with Control-C.

For a copied/extracted folder, run `python3 /path/to/prototypes/serve.py`.
The server resolves assets relative to itself, rather than your terminal's
current directory. It binds only to 127.0.0.1.

## Saved behaviour and evidence boundaries

The prototype includes the simulated menu bar, both icon concepts, the nine gate
overview/detail views, persistent gate navigation, one Tessl Registry section,
the searchable grouped chooser and the comparison controls. Reloading resets
temporary selections; URL parameters retain the requested variant and example.

The inventory is a saved filesystem snapshot, not a live discovery service.
Scores and drift reflect the previously inspected observation; they are not
fresh checks. Reference assessments are labelled fixtures. Refresh is simulated;
copy actions write text, never execute commands. External Tessl links need network
access. The recording layout does not record video by itself.

The native app remains separate. Borumi native QA recordings are retained in the
local SkillsProof Native QA project; they are not bundled with this prototype.

Check the files without starting a server:

```bash
python3 '/Users/jamiecraik/Dev/skillsbar/verification/prototypes/serve.py' --check
```

The prototype files are preserved in local Git history. The companion ZIP
snapshot is an additional local recovery copy; neither is an off-device backup
until separately copied or pushed. This is a design artifact, not an app release.
