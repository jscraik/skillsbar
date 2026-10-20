#!/bin/bash
set -eu
prototype_directory="$(cd -- "$(dirname -- "$0")" && pwd)"
exec python3 "$prototype_directory/serve.py" "$@"
