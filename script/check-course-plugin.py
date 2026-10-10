#!/usr/bin/env python3
"""Validate the AI for UI plugin selection and Codex invocation metadata."""
import json
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1] / '.codex'
manifest = json.loads((root / '.codex-plugin/plugin.json').read_text())
selected = manifest['skills']
assert manifest['name'] == 'emil-aiforui-course'
assert len(selected) == len(set(selected)) == 28
actual = {(root / path).resolve() for path in selected}
expected = {p.parent.resolve() for p in (root / 'skills').glob('emil-*/SKILL.md')
            if p.parent.name != 'emil-design-eng'}
assert actual == expected, 'Export the course collection; keep emil-design-eng separate'
assert all(p.name.startswith('emil-') and (p / 'SKILL.md').is_file() for p in actual)
assert len(actual) == len(selected), 'Every selected directory must be distinct'
manual = 0
for directory in sorted(actual):
    assert directory.is_relative_to(root.resolve())
    skill = directory / 'SKILL.md'
    header = skill.read_text().split('---', 2)[1]
    name = re.search(r'^name:\s*(.+)$', header, re.M).group(1).strip().strip('\"\'')
    assert name == directory.name
    description = re.search(r'^description:\s*(.+)$', header, re.M).group(1).strip()
    if description.startswith('"'):
        description = json.loads(description)
    else:
        description = description.strip("'")
    assert len(description) <= 1024, name + ': description exceeds the submission limit'
    explicit = bool(re.search(r'^disable-model-invocation:\s*true\s*$', header, re.M))
    sidecar = (directory / 'agents/openai.yaml').read_text()
    assert 'default_prompt: "Use $' + name + ' for this task."' in sidecar
    match = re.search(r'^  allow_implicit_invocation:\s*(true|false)\s*$', sidecar, re.M)
    implicit = not match or match.group(1) == 'true'
    assert implicit != explicit, name + ': invocation policies differ'
    manual += explicit
assert manual == 5
print(f'{len(selected)} skills: {manual} explicit-only, {len(selected) - manual} automatic')
