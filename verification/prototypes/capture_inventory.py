"""Read-only name/path inventory for the isolated menu prototype. No skill source copied."""
import json
from pathlib import Path

home = Path.home()
groups = []
seen = set()


def collect(root, title, suffix, version='—'):
    items = []
    visited = set()

    def visit(directory, depth=0):
        try:
            real = directory.resolve(strict=True)
            if depth >= 32 or real in visited:
                return
            visited.add(real)
            for child in sorted(directory.iterdir()):
                if child.name.startswith('.'):
                    continue
                if child.is_dir():
                    visit(child, depth + 1)
                elif child.name == 'SKILL.md' and child.resolve() not in seen:
                    seen.add(child.resolve())
                    name = child.parent.name
                    path = str(child).replace(str(home), '~', 1)
                    items.append(dict(name=name, label=name + suffix, path=path,
                                      version='0.3.0' if name == 'simplify' and suffix == ' · Agents' else version))
        except OSError:
            return

    visit(root)
    if items:
        group = next((group for group in groups if group['title'] == title), None)
        if group is None:
            groups.append(dict(title=title, items=sorted(items, key=lambda i: i['label'].lower())))
        else:
            group['items'] = sorted(group['items'] + items, key=lambda i: i['label'].lower())


collect(Path('/Users/jamiecraik/Dev/agent-skills/Skills'), 'Source checkout', '')
# App discovery deduplicates home aliases independently of source inventory.
seen.clear()
collect(home / '.codex/skills', 'Codex skills', ' · Codex')
collect(home / '.codex/skills/.system', 'Codex skills', ' · Codex')
collect(home / '.agents/skills', 'Shared agent skills', ' · Agents')
cache = home / '.codex/plugins/cache'
for provider in sorted(cache.iterdir()):
    if not provider.is_dir() or provider.name.startswith('.'):
        continue
    for plugin in sorted(provider.iterdir()):
        if not plugin.is_dir() or plugin.name.startswith('.'):
            continue
        for version in sorted(plugin.iterdir()):
            if version.is_dir() and not version.name.startswith('.'):
                collect(version / 'skills', plugin.name + ' ' + version.name,
                        ' · ' + plugin.name + ' ' + version.name, version.name)
Path(__file__).with_name('inventory.js').write_text('window.skillInventory = ' + json.dumps(groups, indent=2) + ';\n')
print(f'{len(groups)} groups, {sum(len(g["items"]) for g in groups)} entries captured')
