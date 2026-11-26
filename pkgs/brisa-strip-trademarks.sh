#!/usr/bin/env bash
# Remove de uma árvore de tema os arquivos com logos/marcas de terceiros
# (Apple, Microsoft/Windows, logos de distribuição) e os links que ficarem quebrados.
# uso: brisa-strip-trademarks.sh <dir>
set -euo pipefail
[[ $# -eq 1 && -d "$1" ]] || { echo "uso: $(basename "$0") <dir>" >&2; exit 2; }
find "$1" -depth \( -iname '*apple*' -o -iname '*microsoft*' -o -iname '*logo-windows*' \
  -o -iname '*windows-logo*' -o -iname 'start-here*' -o -iname 'distributor-logo*' \) -exec rm -rf {} +
find "$1" -type l ! -exec test -e {} \; -delete
