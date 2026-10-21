"""Real-SDK neighbours for malformed retained validation receipt rejection."""
import argparse
import copy
import json
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser(description=__doc__)
for name in ('sdk-python', 'root', 'revision', 'presentation', 'content'):
    parser.add_argument('--'+name, required=True)
args = parser.parse_args()
bridge = Path(__file__).resolve().parents[1]/'Sources/SkillsBar/Resources/verify_validation_receipts.py'
presentation = json.loads(Path(args.presentation).read_text())
content = json.loads(Path(args.content).read_text())
cases = ['valid', 'missing-assessment', 'assessment-gap', 'incoherent-presentation']
with tempfile.TemporaryDirectory(prefix='skillsbar-validation-proof-') as temporary:
    output = Path(temporary).resolve()
    for case in cases:
        p, c = copy.deepcopy(presentation), copy.deepcopy(content)
        if case == 'missing-assessment':
            c.pop('assessment')
        elif case == 'assessment-gap':
            c['assessment']['items'][0]['status'] = 'gap'
        elif case == 'incoherent-presentation':
            p['copy_approval']['accurate'] = False
        pp, cp = output/'presentation.json', output/'content.json'
        pp.write_text(json.dumps(p))
        cp.write_text(json.dumps(c))
        result = subprocess.run([args.sdk_python, '-I', str(bridge), args.root, args.revision, str(pp), str(cp)],
            capture_output=True, text=True, timeout=45, check=False)
        expected = 0 if case == 'valid' else 2
        assert result.returncode == expected, (case, result.returncode, result.stdout, result.stderr)
        assert result.stdout.strip() == 'pass' if case == 'valid' else result.stderr.startswith('blocked: ')
print(json.dumps({'status': 'pass', 'cases': cases, 'source_mutated': False}))
