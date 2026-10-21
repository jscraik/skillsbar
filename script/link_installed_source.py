#!/usr/bin/env python3
"""Link an installed plugin to an SDK-verified source capture; never edit either."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sdk', type=Path, required=True)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--installed', type=Path, required=True)
    parser.add_argument('--source-revision', required=True)
    parser.add_argument('--links', type=Path, required=True)
    parser.add_argument('--source-review', type=Path, help='Existing candidate-bound supplied ownership/provenance review')
    parser.add_argument('--standalone', action='store_true', help='Retain a read-only SDK standalone comparison, including drift; never clears managed plugin gates')
    args = parser.parse_args()
    sdk, source, installed = (p.resolve(strict=True) for p in (args.sdk, args.source, args.installed))
    links = args.links.resolve()
    if links.is_relative_to(source) or links.is_relative_to(installed):
        parser.error('link storage must be outside both packages')
    if args.standalone:
        if args.source_review:
            parser.error('standalone comparisons do not admit plugin source reviews')
        process = subprocess.run([str(sdk), 'compare-copy', str(source), str(installed),
                                  '--source-revision', args.source_revision, '--json'],
                                 capture_output=True, text=True, timeout=45, check=False)
        capture = json.loads(process.stdout)
        if (process.returncode not in (0, 2)
                or capture.get('schema_version') != 'runtime-copy-comparison/v1'
                or capture.get('status') not in ('pass', 'drift')):
            raise SystemExit('SDK standalone comparison blocked; no link saved')
        data = (json.dumps(capture, sort_keys=True) + '\n').encode()
        links.mkdir(parents=True, exist_ok=True)
        digest = hashlib.sha256(data).hexdigest()
        receipt = links / f'{digest}.comparison.json'
        receipt.write_bytes(data)
        link = dict(schema_version='skillsbar-source-link/v1', package_kind='skill',
                    installed_root=str(installed), source_root=str(source), source_revision=args.source_revision,
                    sdk_executable=str(sdk), validation_path=str(receipt), validation_sha256=digest)
        destination = links / (hashlib.sha256(str(installed).encode()).hexdigest() + '.json')
        staged = destination.with_suffix('.new')
        staged.write_text(json.dumps(link, indent=2) + '\n')
        staged.replace(destination)
        print(json.dumps(dict(status='linked', comparison_status=capture['status'],
                              different_paths=capture['different_paths'], link=str(destination), release_ready=False)))
        return
    base = [str(sdk), 'validate-plugin']
    policy = ['--source-revision', args.source_revision, '--require-version', '--require-description', '--json', '--robot']

    def run(root, evidence=None):
        command = base + [str(root)] + policy
        if evidence is not None:
            command += ['--verify-evidence', str(evidence)]
        process = subprocess.run(command, capture_output=True, text=True, timeout=45, check=False)
        if process.returncode != 0:
            raise SystemExit(f'SDK validation blocked (exit {process.returncode}); no link saved.\n{process.stdout}\n{process.stderr}')
        payload = json.loads(process.stdout)
        if payload.get('schema_version') != 'plugin-package-validation/v1' or payload.get('status') != 'pass':
            raise SystemExit('SDK did not return a passing plugin capture; no link saved')
        return payload

    capture = run(source)
    # Let the SDK own schema, identity, bytes and permission comparison.
    with tempfile.TemporaryDirectory(prefix='skillsbar-source-link-') as temporary:
        evidence = Path(temporary).resolve() / 'validation.json'
        evidence.write_text(json.dumps(capture, sort_keys=True) + '\n')
        run(source, evidence)
        run(installed, evidence)
        data = evidence.read_bytes()
    links.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256(data).hexdigest()
    receipt = links / f'{digest}.validation.json'
    if receipt.exists() and receipt.read_bytes() != data:
        raise SystemExit('existing validation capture differs; no link saved')
    receipt.write_bytes(data)
    link = {
        'schema_version': 'skillsbar-source-link/v1',
        'installed_root': str(installed), 'source_root': str(source),
        'source_revision': args.source_revision, 'sdk_executable': str(sdk),
        'validation_path': str(receipt), 'validation_sha256': digest,
    }
    if args.source_review:
        review_path = args.source_review.resolve(strict=True)
        data = review_path.read_bytes()
        review = json.loads(data)
        if (review.get('schema_version') != 'skillsbar-source-review/v1'
                or review.get('candidate') != capture['candidate']
                or review.get('mode_manifest_sha256') != capture['mode_manifest_sha256']):
            raise SystemExit('Source review belongs to another capture; no link saved')
        link.update(source_review_path=str(review_path), source_review_sha256=hashlib.sha256(data).hexdigest())
    destination = links / (hashlib.sha256(str(installed).encode()).hexdigest() + '.json')
    staged = destination.with_suffix('.new')
    staged.write_text(json.dumps(link, indent=2) + '\n')
    staged.replace(destination)
    print(json.dumps({'status': 'linked', 'link': str(destination), 'validation': str(receipt),
                      'candidate': capture['candidate'], 'release_ready': False}))


if __name__ == '__main__':
    main()
