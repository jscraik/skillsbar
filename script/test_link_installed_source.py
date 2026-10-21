#!/usr/bin/env python3
"""Exercise the link helper against a real, explicitly supplied Skills SDK CLI."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, required=True)
    args = parser.parse_args()
    sdk = args.sdk.resolve(strict=True)
    revision = 'a' * 40
    with tempfile.TemporaryDirectory(prefix='skillsbar-sdk-link-test-') as temporary:
        root = Path(temporary).resolve()
        source, installed, links = (root / name for name in ('source', 'installed', 'links'))
        (source / 'skills/check').mkdir(parents=True)
        (source / '.codex-plugin').mkdir()
        (source / 'plugin.json').write_text(json.dumps({
            '$schema': 'https://agent-plugins.org/schemas/1.0.0/plugin.schema.json',
            'name': 'link-fixture', 'version': '0.1.1', 'description': 'Isolated SDK integration fixture.'
        }))
        (source / 'skills/check/SKILL.md').write_text('---\nname: check\ndescription: Check a fixture.\n---\nRead the fixture.\n')
        (source / '.codex-plugin/plugin.json').write_text('{"interface":{"displayName":"Fixture"}}')
        shutil.copytree(source, installed)
        helper = Path(__file__).with_name('link_installed_source.py')
        command = [sys.executable, str(helper), '--sdk', str(sdk), '--source', str(source),
                   '--installed', str(installed), '--source-revision', revision, '--links', str(links)]
        linked = subprocess.run(command, capture_output=True, text=True, timeout=150, check=True)
        link_path = Path(json.loads(linked.stdout)['link'])
        before_link = link_path.read_bytes()
        evidence = json.loads(before_link)['validation_path']

        def verify(package, status):
            process = subprocess.run([str(sdk), 'validate-plugin', str(package), '--source-revision', revision,
                '--require-version', '--require-description', '--json', '--robot', '--verify-evidence', evidence],
                capture_output=True, text=True, timeout=45, check=False)
            payload = json.loads(process.stdout)
            assert process.returncode == (0 if status == 'pass' else 2), process.stdout
            assert payload['status'] == status and payload['schema_version'] == 'plugin-package-validation/v1'
            if status == 'blocked':
                assert any(f['code'] == 'plugin_evidence_mismatch' for f in payload['findings']), payload

        verify(source, 'pass')
        verify(installed, 'pass')
        overlay = installed / '.codex-plugin/plugin.json'
        original = overlay.read_bytes()
        overlay.write_text('{"interface":{"displayName":"Changed"}}')
        verify(installed, 'blocked')
        failed = subprocess.run(command, capture_output=True, text=True, timeout=150, check=False)
        assert failed.returncode != 0 and link_path.read_bytes() == before_link
        overlay.write_bytes(original)
        verify(installed, 'pass')
        original_mode = overlay.stat().st_mode & 0o777
        overlay.chmod(0o600 if original_mode != 0o600 else 0o644)
        verify(installed, 'blocked')
        overlay.chmod(original_mode)
        verify(installed, 'pass')
        (source / 'skills/check/SKILL.md').write_text('---\nname: check\ndescription: Changed source.\n---\n')
        verify(source, 'blocked')
        print(json.dumps({'status': 'pass', 'sdk': str(sdk), 'cases': [
            'matching source and installed', 'hidden installed drift', 'failed relink preserves record',
            'restoration', 'permission drift', 'source drift']}))


if __name__ == '__main__':
    main()
