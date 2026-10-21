"""Read-only SDK bridge: full contract validation and fresh semantic reassessment."""
import json
from pathlib import Path
import sys

from skills_sdk.core.schema_registry import SchemaRegistry
from skills_sdk.models.content_review import ContentReviewResult
from skills_sdk.models.plugin import PluginValidationPolicy
from skills_sdk.models.plugin_presentation import PluginPresentationCheck
from skills_sdk.validation.content_review import assess_content_review
from skills_sdk.validation.plugin_package import validate_plugin_package
from skills_sdk.validation.plugin_presentation import check_plugin_presentation


def verify(root, revision, presentation_path, content_paths):
    registry = SchemaRegistry()
    capture = validate_plugin_package(root, source_revision=revision,
        policy=PluginValidationPolicy(require_version=True, require_description=True))
    if capture.status != 'pass':
        raise ValueError('Current plugin validation blocked')
    payload = json.loads(presentation_path.read_bytes())
    registry.validate('plugin-presentation-check.v1', payload)
    presentation = PluginPresentationCheck.model_validate(payload)
    if (presentation.status != 'pass' or presentation.candidate != capture.candidate
            or presentation.mode_manifest_sha256 != capture.mode_manifest_sha256):
        raise ValueError('Presentation does not bind current source')
    request = {'candidate': presentation.candidate.model_dump(mode='json'),
        'mode_manifest_sha256': presentation.mode_manifest_sha256,
        'image_approvals': [image.approval.model_dump(mode='json') for image in presentation.images],
        'copy_approval': presentation.copy_approval.model_dump(mode='json')}
    fresh = check_plugin_presentation(root, source_revision=revision, request=request)
    if fresh.status != 'pass' or fresh != presentation:
        raise ValueError('Fresh presentation evidence differs')
    remaining = {child.path: child.validation.candidate for child in capture.skills}
    if len(content_paths) != len(remaining):
        raise ValueError('Incomplete child review coverage')
    for path in content_paths:
        payload = json.loads(path.read_bytes())
        registry.validate('content-review.v1', payload)
        content = ContentReviewResult.model_validate(payload)
        matches = [key for key, candidate in remaining.items() if candidate == content.candidate]
        if content.status != 'pass' or len(matches) != 1 or content.assessment is None:
            raise ValueError('Incomplete or foreign content review')
        child = matches[0]
        fresh = assess_content_review(root/child, source_revision=revision, assessment=content.assessment)
        if fresh.status != 'pass' or fresh != content:
            raise ValueError('Fresh content evidence differs')
        del remaining[child]
    if remaining:
        raise ValueError('Missing child review')


if __name__ == '__main__':
    try:
        verify(Path(sys.argv[1]), sys.argv[2], Path(sys.argv[3]), [Path(p) for p in sys.argv[4:]])
    except Exception as error:
        print('blocked: ' + type(error).__name__, file=sys.stderr)
        sys.exit(2)
    print('pass')
