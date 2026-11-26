#!/usr/bin/env bash
# Roda toda a validação estática local.
set -euo pipefail
cd "$(dirname "$0")/.."
bats tests/static
find scripts -type f -exec shellcheck -x {} +
