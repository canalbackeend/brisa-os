#!/usr/bin/env bash
# Compila pkgs/* e aur/packages.txt (em ordem) num repositório pacman local [brisa].
# Roda como root no container Arch; os builds usam o usuário sem privilégios "builder".
# uso: build-repo.sh <repo_dir>
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ $# -eq 1 ]] || { echo "uso: $(basename "$0") <repo_dir>" >&2; exit 2; }
REPO="$1"; WORK=/tmp/brisa-build

id builder &>/dev/null || useradd -m builder
echo 'builder ALL=(ALL) NOPASSWD: /usr/bin/pacman' > /etc/sudoers.d/builder
mkdir -p "$REPO" "$WORK"
cp -r "$ROOT/pkgs" "$ROOT/branding" "$WORK/"
chown -R builder: "$REPO" "$WORK"
[[ -f "$REPO/brisa.db.tar.gz" ]] || sudo -u builder repo-add "$REPO/brisa.db.tar.gz"
grep -qx '\[brisa\]' /etc/pacman.conf || printf '\n[brisa]\nSigLevel = Optional TrustAll\nServer = file://%s\n' "$REPO" >> /etc/pacman.conf

build_dir() {
  (cd "$1" && sudo -u builder PKGDEST="$REPO" makepkg -s --noconfirm --needed)
  sudo -u builder repo-add -n "$REPO/brisa.db.tar.gz" "$REPO"/*.pkg.tar.zst
  pacman -Sy --noconfirm
}

for d in "$WORK"/pkgs/*/; do build_dir "$d"; done

while read -r name commit; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  dir="$WORK/aur/$name"
  sudo -u builder git clone -q "https://aur.archlinux.org/$name.git" "$dir"
  sudo -u builder git -C "$dir" checkout -q "$commit"
  build_dir "$dir"
done < "$ROOT/aur/packages.txt"

ls -1 "$REPO"
