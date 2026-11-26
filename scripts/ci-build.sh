#!/usr/bin/env bash
# Roda DENTRO do container archlinux (privilegiado): monta repo [brisa], perfil e ISO.
# uso: ci-build.sh <src_dir> <out_dir>
set -euo pipefail
[[ $# -eq 2 ]] || { echo "uso: $(basename "$0") <src_dir> <out_dir>" >&2; exit 2; }
SRC="$1"; OUT="$2"

pacman -Syu --noconfirm --needed archiso git base-devel sudo perl
if [[ -x "$SRC/scripts/build-repo.sh" ]]; then "$SRC/scripts/build-repo.sh" /repo; fi

"$SRC/scripts/assemble-profile.sh" /usr/share/archiso/configs/releng /work/profile
mkarchiso -v -w /work/mk -o "$OUT" /work/profile

cd "$OUT"
for iso in *.iso; do sha256sum "$iso" > "$iso.sha256"; done
ls -lh "$OUT"
