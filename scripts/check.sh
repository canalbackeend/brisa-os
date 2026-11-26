#!/usr/bin/env bash
# Roda toda a validação estática local.
set -euo pipefail
cd "$(dirname "$0")/.."
bats tests/static
find scripts pkgs/brisa-strip-trademarks.sh tests/boot archiso/airootfs/usr/local/bin -type f -name "*" ! -name "*.txt" -exec shellcheck -x {} +
