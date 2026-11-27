#!/usr/bin/env bash
# Inicia a ISO no QEMU/KVM e confere os marcadores BRISA: gravados na serial.
# uso: boot-test.sh [--no-net] [--res LxA] <iso> <uefi|bios> <timeout_s> [chave=valor...]
#   sem chave=valor, usa tests/boot/expected.txt
# Saídas: out/boot-<rótulo>.log (serial) e out/screen-<rótulo>.png (captura da tela).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

net=(-nic "user,model=virtio-net-pci"); res="1360x768"; tag=""
while [[ "${1:-}" == --* ]]; do
  case "$1" in
    --no-net) net=(-nic none); tag="-nonet"; shift ;;
    --res) res="$2"; shift 2 ;;
    *) echo "opção desconhecida: $1" >&2; exit 2 ;;
  esac
done
[[ $# -ge 3 ]] || { echo "uso: $(basename "$0") [--no-net] [--res LxA] <iso> <uefi|bios> <timeout_s> [chave=valor...]" >&2; exit 2; }
iso="$1"; fw="$2"; timeout_s="$3"; shift 3
if [[ $# -gt 0 ]]; then expected=("$@"); else mapfile -t expected < <(grep -v '^\s*$' "$HERE/expected.txt"); fi

label="$fw$tag-$res"; mkdir -p out
log="out/boot-$label.log"; shot="out/screen-$label.ppm"; qmp="$(mktemp -u /tmp/qmp.XXXX.sock)"
: > "$log"

fwargs=()
if [[ "$fw" == uefi ]]; then
  code=/usr/share/OVMF/OVMF_CODE_4M.fd; vars="$(mktemp /tmp/vars.XXXX.fd)"
  cp /usr/share/OVMF/OVMF_VARS_4M.fd "$vars"
  fwargs=(-drive "if=pflash,format=raw,readonly=on,file=$code" -drive "if=pflash,format=raw,file=$vars")
fi

qemu-system-x86_64 -enable-kvm -machine q35 -cpu host -smp 2 -m 4096 \
  "${fwargs[@]}" -cdrom "$iso" -boot d "${net[@]}" \
  -vga none -device "virtio-vga,edid=on,xres=${res%x*},yres=${res#*x}" -display none \
  -serial "file:$log" -qmp "unix:$qmp,server,nowait" &
qpid=$!

qmp_cmd() {
  python3 - "$qmp" "$1" <<'PY'
import json, socket, sys
s = socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); f = s.makefile('rw')
f.readline()
for cmd in ({"execute": "qmp_capabilities"}, json.loads(sys.argv[2])):
    f.write(json.dumps(cmd) + "\n"); f.flush(); f.readline()
PY
}

deadline=$(( SECONDS + timeout_s ))
until tr -d '\r' < "$log" | grep -qx 'BRISA:selftest=done'; do
  if (( SECONDS > deadline )) || ! kill -0 "$qpid" 2>/dev/null; then echo "tempo esgotado ou QEMU encerrou"; break; fi
  sleep 5
done

qmp_cmd "{\"execute\":\"screendump\",\"arguments\":{\"filename\":\"$PWD/$shot\"}}" || true
kill "$qpid" 2>/dev/null || true; wait "$qpid" 2>/dev/null || true
if command -v convert >/dev/null && [[ -f "$shot" ]]; then convert "$shot" "${shot%.ppm}.png" && rm -f "$shot"; fi

echo "--- marcadores BRISA ($label) ---"; tr -d '\r' < "$log" | grep '^BRISA:' || true
"$HERE/check-markers.sh" "$log" "${expected[@]}"
