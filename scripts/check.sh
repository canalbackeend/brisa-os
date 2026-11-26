#!/usr/bin/env bash
# Roda toda a validação estática local.
set -euo pipefail
cd "$(dirname "$0")/.."
bats tests/static
find scripts tests/boot archiso/airootfs/usr/local/bin -type f -name "*" ! -name "*.txt" -exec shellcheck -x {} +
