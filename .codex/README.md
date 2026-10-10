# AI for UI Codex plugin

The `emil-aiforui-course` plugin exports the 28 existing `emil-*` skills in
this directory. Its manifest selects those directories directly, so skill
instructions and references have one source of truth.

Add the repository marketplace, then install its plugin:

```sh
codex plugin marketplace add jscraik/skillsbar
codex plugin add emil-aiforui-course@skillsbar
```

The five skills marked `disable-model-invocation: true` also declare Codex's
explicit-only policy in `agents/openai.yaml`. Installation does not change
user-level enabled/disabled choices. The two longest trigger descriptions
fit the published 1024-character skill metadata limit; their instruction
bodies are unchanged.

Validate the exported selection and invocation policies from the repository
root:

```sh
python3 script/check-course-plugin.py
```

This checks selected directories and invocation metadata, not the behavior or quality of
every workflow. It does not build or launch the SkillsBar application.
