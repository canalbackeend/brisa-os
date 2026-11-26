#!/usr/bin/env bash
# Autoteste: instalador presente, configurado e com os módulos Python compilados.
MODS="${BRISA_CALAMARES_MODULES:-/usr/lib/calamares/modules}"
SETTINGS="${BRISA_CALAMARES_SETTINGS:-/etc/calamares/settings.conf}"
ok=1
command -v calamares >/dev/null || ok=0
[[ -f "$SETTINGS" ]] || ok=0
for m in unpackfs bootloader mount fstab initcpio; do
  [[ -f "$MODS/$m/module.desc" ]] || { [[ "$m" == unpackfs || "$m" == bootloader ]] && ok=0; }
done
if (( ok )); then echo "BRISA:calamares=present"; else echo "BRISA:calamares=ausente"; fi
